import Flutter
import CoreMotion
import HealthKit
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    applyDataProtectionToAppStorage()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    HealthKitBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
    ActivityMotionBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
    PackagingOCRBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
    AppSettingsBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func applyDataProtectionToAppStorage() {
    let manager = FileManager.default
    let directories: [FileManager.SearchPathDirectory] = [
      .documentDirectory,
      .applicationSupportDirectory,
    ]
    for directory in directories {
      guard let url = manager.urls(for: directory, in: .userDomainMask).first else { continue }
      try? manager.createDirectory(at: url, withIntermediateDirectories: true)
      try? manager.setAttributes(
        [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
        ofItemAtPath: url.path
      )
    }
  }
}

private final class ActivityMotionBridge: NSObject, FlutterStreamHandler {
  private static var shared: ActivityMotionBridge?
  private let activityManager = CMMotionActivityManager()
  private let pedometer = CMPedometer()
  private var sink: FlutterEventSink?
  private var activity: CMMotionActivity?
  private var cadence: Double?

  static func register(messenger: FlutterBinaryMessenger) {
    let bridge = ActivityMotionBridge()
    shared = bridge
    FlutterEventChannel(name: "balance/activity_motion", binaryMessenger: messenger)
      .setStreamHandler(bridge)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    guard CMMotionActivityManager.isActivityAvailable() || CMPedometer.isStepCountingAvailable() else {
      emit(available: false)
      return nil
    }
    if CMMotionActivityManager.isActivityAvailable() {
      activityManager.startActivityUpdates(to: .main) { [weak self] activity in
        self?.activity = activity
        self?.emit(available: true)
      }
    }
    if CMPedometer.isStepCountingAvailable() {
      pedometer.startUpdates(from: Date()) { [weak self] data, _ in
        DispatchQueue.main.async {
          self?.cadence = data?.currentCadence?.doubleValue
          self?.emit(available: true)
        }
      }
    }
    emit(available: true)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    activityManager.stopActivityUpdates()
    pedometer.stopUpdates()
    sink = nil
    activity = nil
    cadence = nil
    return nil
  }

  private func emit(available: Bool) {
    var payload: [String: Any] = [
      "available": available,
      "stationary": activity?.stationary == true,
      "walking": activity?.walking == true,
      "running": activity?.running == true,
    ]
    payload["cadence"] = cadence ?? 0
    sink?(payload)
  }
}

private final class AppSettingsBridge {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "balance/app_settings", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "open", let url = URL(string: UIApplication.openSettingsURLString) else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    }
  }
}

private final class PackagingOCRBridge {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "balance/package_ocr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String,
            let image = UIImage(contentsOfFile: path)?.cgImage else {
        result(FlutterError(code: "invalid_image", message: nil, details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let request = VNRecognizeTextRequest { request, error in
          DispatchQueue.main.async {
            if let error {
              result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
              return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            result(text)
          }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US"]
        do {
          try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }
}

private final class HealthKitBridge {
  private static let channelName = "balance/healthkit"
  private static let requestedKey = "balance.healthkit.steps.requested"
  private static let store = HKHealthStore()

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getStatus":
        getStatus(result: result)
      case "requestAccess":
        requestAccess(result: result)
      case "readTodaySteps":
        readTodaySteps(result: result)
      case "openSettings":
        openSettings(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func stepType() -> HKQuantityType? {
    HKObjectType.quantityType(forIdentifier: .stepCount)
  }

  private static func getStatus(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(), let steps = stepType() else {
      result("restricted")
      return
    }
    store.getRequestStatusForAuthorization(toShare: [], read: [steps]) { status, error in
      DispatchQueue.main.async {
        if error != nil {
          result("restricted")
          return
        }
        if status == .shouldRequest {
          result("notDetermined")
          return
        }
        let requested = UserDefaults.standard.bool(forKey: requestedKey)
        result(requested ? "authorized" : "notDetermined")
      }
    }
  }

  private static func requestAccess(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(), let steps = stepType() else {
      result("restricted")
      return
    }
    store.requestAuthorization(toShare: [], read: [steps]) { success, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(
            code: "denied",
            message: error.localizedDescription,
            details: nil
          ))
          return
        }
        guard success else {
          result("denied")
          return
        }
        UserDefaults.standard.set(true, forKey: requestedKey)
        result("authorized")
      }
    }
  }

  private static func readTodaySteps(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable(), let steps = stepType() else {
      result(FlutterError(code: "restricted", message: nil, details: nil))
      return
    }
    let now = Date()
    let start = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(
      withStart: start,
      end: now,
      options: [.strictStartDate, .strictEndDate]
    )
    let query = HKStatisticsQuery(
      quantityType: steps,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, statistics, error in
      DispatchQueue.main.async {
        if let error = error as? HKError, error.code == .errorAuthorizationDenied {
          result(FlutterError(code: "denied", message: error.localizedDescription, details: nil))
          return
        }
        if let error {
          result(FlutterError(code: "query_failed", message: error.localizedDescription, details: nil))
          return
        }
        let count = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
        result(Int(count.rounded()))
      }
    }
    store.execute(query)
  }

  private static func openSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened)
    }
  }
}
