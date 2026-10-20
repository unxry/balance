import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final directory = Directory(Platform.environment['BALANCE_SCREENSHOT_DIR']!);
  await directory.create(recursive: true);
  Future<void> capture(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(await driver.screenshot());
    stdout.writeln('CAPTURED $name');
  }

  Future<void> command(String value) async {
    await driver.requestData(value);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  try {
    await driver.waitUntilFirstFrameRasterized();
    await driver.runUnsynchronized(() async {
      for (final language in ['ru', 'en']) {
        for (final theme in ['light', 'dark']) {
          final name = '$language-$theme';
          await command(language);
          await command(theme);
          await command('screen-home');
          await capture('$name-home');
          await command('screen-advice');
          await capture('$name-advice');
          await driver.scroll(
            find.byValueKey('tipsAdviceScroll'),
            0,
            -600,
            const Duration(milliseconds: 400),
          );
          await capture('$name-article');
          await command('screen-home');
          await command('insights-plateau');
          await command('screen-insights');
          await capture('$name-plateau');
          await driver.scroll(
            find.byValueKey('weightInsightsScroll'),
            0,
            -520,
            const Duration(milliseconds: 400),
          );
          await capture('$name-context');
          await command('screen-home');
          await command('insights-short');
          await command('screen-insights');
          await capture('$name-short');
          await command('screen-home');
          await command('screen-library');
          await capture('$name-library');
        }
      }
    });
  } finally {
    await driver.close();
  }
}
