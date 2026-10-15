import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum StepAccessState {
  loading,
  unavailable,
  notDetermined,
  authorized,
  denied,
  restricted,
}

class HealthServiceException implements Exception {
  final String code;
  const HealthServiceException(this.code);
}

class HealthService {
  static const MethodChannel _channel = MethodChannel('balance/healthkit');

  Future<StepAccessState> getStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return StepAccessState.unavailable;
    }
    try {
      final value = await _channel.invokeMethod<String>('getStatus');
      return _parseStatus(value);
    } on MissingPluginException {
      return StepAccessState.unavailable;
    } on PlatformException catch (error) {
      if (error.code == 'restricted') return StepAccessState.restricted;
      return StepAccessState.unavailable;
    }
  }

  Future<StepAccessState> requestAccess() async {
    try {
      final value = await _channel.invokeMethod<String>('requestAccess');
      return _parseStatus(value);
    } on PlatformException catch (error) {
      if (error.code == 'denied') return StepAccessState.denied;
      if (error.code == 'restricted') return StepAccessState.restricted;
      throw HealthServiceException(error.code);
    }
  }

  Future<int> readTodaySteps() async {
    try {
      final value = await _channel.invokeMethod<int>('readTodaySteps');
      return (value ?? 0).clamp(0, 1000000);
    } on PlatformException catch (error) {
      if (error.code == 'denied') {
        throw const HealthServiceException('denied');
      }
      throw HealthServiceException(error.code);
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // No settings destination on unsupported platforms.
    }
  }

  StepAccessState _parseStatus(String? value) {
    switch (value) {
      case 'authorized':
        return StepAccessState.authorized;
      case 'denied':
        return StepAccessState.denied;
      case 'restricted':
        return StepAccessState.restricted;
      case 'notDetermined':
        return StepAccessState.notDetermined;
      default:
        return StepAccessState.unavailable;
    }
  }
}
