import AVFoundation
import Foundation

guard (4...5).contains(CommandLine.arguments.count),
      let duration = Double(CommandLine.arguments[3]) else {
  fatalError("Usage: normalize_runtime_video.swift <input> <output> <duration-seconds> [start-seconds]")
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let asset = AVURLAsset(url: input)
let composition = AVMutableComposition()
let sourceDuration = try await asset.load(.duration)
let start = CMTime(
  seconds: CommandLine.arguments.count == 5 ? Double(CommandLine.arguments[4])! : 0,
  preferredTimescale: 600
)
let available = CMTimeSubtract(sourceDuration, start)
let clipDuration = min(available, CMTime(seconds: duration, preferredTimescale: 600))

for sourceTrack in try await asset.loadTracks(withMediaType: .video) {
  let track = composition.addMutableTrack(
    withMediaType: .video,
    preferredTrackID: kCMPersistentTrackID_Invalid
  )!
  try track.insertTimeRange(
    CMTimeRange(start: start, duration: clipDuration),
    of: sourceTrack,
    at: .zero
  )
  track.preferredTransform = try await sourceTrack.load(.preferredTransform)
}

composition.scaleTimeRange(
  CMTimeRange(start: .zero, duration: clipDuration),
  toDuration: CMTime(seconds: duration, preferredTimescale: 600)
)
try? FileManager.default.removeItem(at: output)
let exporter = AVAssetExportSession(
  asset: composition,
  presetName: AVAssetExportPresetHighestQuality
)!
exporter.outputURL = output
exporter.outputFileType = .mp4
await exporter.export()
