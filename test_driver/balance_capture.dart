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
      final scroll = find.byValueKey('weightHistoryScroll');
      Future<void> top() =>
          driver.scroll(scroll, 0, 1800, const Duration(milliseconds: 400));
      Future<void> down(double amount) =>
          driver.scroll(scroll, 0, -amount, const Duration(milliseconds: 400));
      Future<void> mode(int index) async {
        await driver.tap(find.byValueKey('progressMode-$index'));
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }

      await driver.tap(find.byValueKey('rootTab-weight'));
      if (Platform.environment['BALANCE_CAPTURE_MEASUREMENTS_ONLY'] == '1') {
        await mode(1);
        await capture('measurements-cards');
        await driver.scrollIntoView(
          find.byValueKey('bodyChart-см'),
          alignment: .25,
        );
        await capture('measurements-chart');
        await top();
        await mode(2);
        await capture('comparison-top');
        await driver.scrollIntoView(
          find.byValueKey('comparisonDate'),
          alignment: .25,
        );
        await capture('comparison-values');
        await top();
        await mode(1);
        await driver.tap(find.byValueKey('addWeightButton'));
        await driver.tap(find.byValueKey('bodyType-waist'));
        await capture('waist-editor');
        return;
      }
      if (Platform.environment['BALANCE_CAPTURE_PERIODS_ONLY'] == '1') {
        for (final period in ['m3', 'year']) {
          await top();
          await driver.tap(find.byValueKey('weightRange-$period'));
          await Future<void>.delayed(const Duration(milliseconds: 450));
          await driver.scrollIntoView(
            find.byValueKey('weightFullChart'),
            alignment: .25,
          );
          await capture('weight-$period');
        }
        return;
      }
      await capture('weight');
      await driver.scrollIntoView(
        find.byValueKey('forecastReady'),
        alignment: .65,
      );
      await capture('weight-forecast');
      await top();
      await driver.requestData('sparse');
      await driver.scrollIntoView(
        find.byValueKey('forecastWaiting'),
        alignment: .65,
      );
      await capture('weight-insufficient');
      await top();
      await driver.requestData('restore');
      await driver.tap(find.byValueKey('weightRange-week'));
      await driver.scrollIntoView(
        find.byValueKey('forecastReady'),
        alignment: .65,
      );
      await capture('weight-week');
      await top();
      await driver.tap(find.byValueKey('weightRange-month'));
      await mode(1);
      await capture('measurements-cards');
      await driver.scrollIntoView(
        find.byValueKey('bodyChart-см'),
        alignment: .25,
      );
      await capture('measurements-chart');
      await top();
      await mode(2);
      await capture('comparison-top');
      await down(365);
      await capture('comparison-panel');
      await driver.scroll(
        find.byValueKey('bodyChart-кг'),
        130,
        45,
        const Duration(milliseconds: 500),
      );
      await capture('comparison-selection');
      await driver.scrollIntoView(
        find.byValueKey('comparisonDate'),
        alignment: .45,
      );
      await capture('comparison-values');
      await driver.requestData('dark');
      await capture('comparison-dark');
      await driver.requestData('en');
      await capture('comparison-en');
      await driver.requestData('light');
      await driver.requestData('ru');
      await driver.requestData('sparse-all');
      await top();
      await mode(0);
      await driver.scrollIntoView(
        find.byValueKey('forecastWaiting'),
        alignment: .65,
      );
      await capture('weight-two');
      await top();
      await mode(1);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await driver.scrollIntoView(
        find.byValueKey('bodyChart-см'),
        alignment: .25,
      );
      await capture('measurements-two');
      await top();
      await mode(2);
      await capture('comparison-two-top');
      await down(365);
      await capture('comparison-two');
      await top();
      await mode(0);
      await driver.requestData('single');
      await driver.scrollIntoView(
        find.byValueKey('forecastWaiting'),
        alignment: .65,
      );
      await capture('weight-one');
      await driver.requestData('empty');
      await capture('weight-empty');
      await driver.requestData('restore-all');
      await driver.requestData('en');
      await driver.requestData('close');
      await top();
      await mode(1);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await driver.scrollIntoView(
        find.byValueKey('bodyChart-cm'),
        alignment: .25,
      );
      await capture('measurements-close');
      await driver.requestData('large');
      await top();
      await capture('measurements-large-reduced-motion');
    });
  } finally {
    await driver.close();
  }
}
