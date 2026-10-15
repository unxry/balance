import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final directory = Directory(
    Platform.environment['BALANCE_SCREENSHOT_DIR'] ??
        '/tmp/balance_screenshots',
  );
  await directory.create(recursive: true);
  Future<void> capture(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(await driver.screenshot());
    stdout.writeln('CAPTURED $name');
  }

  try {
    await driver.waitUntilFirstFrameRasterized();
    await driver.runUnsynchronized(() async {
      await driver.tap(find.byValueKey('rootTab-weight'));
      await capture('weight');
      for (final period in ['week', 'm3', 'year', 'month']) {
        await driver.tap(find.byValueKey('weightRange-$period'));
      }
      await driver.tap(find.byValueKey('progressMode-1'));
      await capture('measurements-top');
      await driver.scroll(
        find.byValueKey('weightHistoryScroll'),
        0,
        -310,
        const Duration(milliseconds: 450),
      );
      await capture('measurements-chart');
      await driver.scroll(
        find.byValueKey('weightHistoryScroll'),
        0,
        1100,
        const Duration(milliseconds: 450),
      );
      await driver.tap(find.byValueKey('progressMode-2'));
      await capture('comparison-top');
      await driver.scroll(
        find.byValueKey('weightHistoryScroll'),
        0,
        -310,
        const Duration(milliseconds: 450),
      );
      await capture('comparison-charts');
      await driver.requestData('dark');
      await capture('comparison-dark');
      await driver.requestData('light');
      await driver.tap(find.byValueKey('rootTab-home'));
      await driver.scrollIntoView(
        find.byValueKey('adviceCard'),
        alignment: .35,
      );
      await driver.tap(find.byValueKey('adviceCard'));
      await driver.waitFor(find.byValueKey('adviceDetailSheet'));
      await capture('daily-tip');
      final id = await driver.requestData('tip');
      await driver.tap(find.byValueKey('saveTip-$id'));
      await driver.requestData('dark');
      await capture('daily-tip-dark');
      await driver.requestData('en');
      await capture('daily-tip-en');
      await driver.scrollIntoView(
        find.byValueKey('tipHistory'),
        alignment: .65,
      );
      await driver.tap(find.byValueKey('tipHistory'));
      await capture('tip-history');
    });
  } finally {
    await driver.close();
  }
}
