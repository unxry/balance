import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final directory = Directory(Platform.environment['BALANCE_SCREENSHOT_DIR']!);
  await directory.create(recursive: true);
  Future<void> command(String s) async {
    await driver.requestData(s);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> shot(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(await driver.screenshot());
    stdout.writeln('CAPTURED $name');
  }

  final pairs = Platform.environment['BALANCE_QA_PAIRS'] == 'compact'
      ? [('ru', 'light'), ('en', 'dark')]
      : [('ru', 'light'), ('ru', 'dark'), ('en', 'light'), ('en', 'dark')];
  try {
    await driver.waitUntilFirstFrameRasterized();
    await driver.runUnsynchronized(() async {
      for (final pair in pairs) {
        final name = '${pair.$1}-${pair.$2}';
        await command(pair.$1);
        await command(pair.$2);
        await command('screen-home');
        await command('action-breakfast');
        await driver.scrollIntoView(
          find.byValueKey('adviceCard'),
          alignment: .65,
        );
        await shot('$name-home');
        await command('screen-advice');
        await shot('$name-action');
        await driver.scrollIntoView(find.byValueKey('tryTip-meal-breakfast'));
        await driver.tap(find.byValueKey('tryTip-meal-breakfast'));
        await driver.scrollIntoView(
          find.byValueKey('completeTip-2026-10-15'),
          alignment: .75,
        );
        await driver.tap(find.byValueKey('completeTip-2026-10-15'));
        await command('await-tips');
        await shot('$name-steps-done');
        await driver.scrollIntoView(
          find.byValueKey('tipSubstitute-meal-breakfast'),
          alignment: .5,
        );
        await driver.tap(find.byValueKey('tipSubstitute-meal-breakfast'));
        await shot('$name-substitution');
        await driver.scrollIntoView(find.byValueKey('chooseTipAlternative'));
        await driver.tap(find.byValueKey('chooseTipAlternative'));
        await shot('$name-choices');
        await command('screen-home');
        await command('insights-plateau');
        await command('action-plateau');
        await command('screen-advice');
        await shot('$name-plateau-plan');
        await command('screen-home');
        await command('screen-insights');
        await shot('$name-insights');
        await command('screen-home');
        await command('screen-library');
        await shot('$name-library');
      }
    });
  } finally {
    await driver.close();
  }
}
