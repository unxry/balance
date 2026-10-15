import 'package:flutter/services.dart';

class AppSettingsService {
  static const _channel = MethodChannel('balance/app_settings');

  const AppSettingsService();

  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('open');
    } on MissingPluginException {
      // Unsupported host (for example widget tests).
    }
  }
}
