import 'package:flutter_app/services/ambient_character_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

String _asset(WidgetTester tester) {
  final image = tester.widgetList<Image>(find.byType(Image)).last;
  return (image.image as AssetImage).assetName;
}

void main() {
  testWidgets('activity_preload_test', (tester) async {
    await tester.runAsync(preloadBalanceActivitySprites);
  });

  testWidgets('activity_walk_runtime_test', (tester) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          size: 68,
          animationMode: BalanceActivityAnimationMode.walk,
        ),
      ),
    );
    final first = _asset(tester);
    await tester.pump(const Duration(milliseconds: 130));
    expect(_asset(tester), isNot(first));
    expect(find.byKey(const ValueKey('activityTicker-active')), findsOneWidget);
  });

  testWidgets('activity_run_runtime_test', (tester) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          size: 68,
          animationMode: BalanceActivityAnimationMode.run,
        ),
      ),
    );
    final first = _asset(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_asset(tester), isNot(first));
  });

  testWidgets('run frame player loops 0 through 15 without sticking', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          size: 68,
          animationMode: BalanceActivityAnimationMode.run,
        ),
      ),
    );
    for (var cycle = 0; cycle < 2; cycle++) {
      for (var frame = 0; frame < 16; frame++) {
        expect(
          _asset(tester),
          endsWith('run_${frame.toString().padLeft(2, '0')}.png'),
        );
        await tester.pump(const Duration(milliseconds: 54));
      }
    }
  });

  testWidgets('activity_ambient_runtime_uses_locked_run_frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          size: 68,
          animationMode: BalanceActivityAnimationMode.ambient,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 801));
    await tester.pump(const Duration(milliseconds: 361));
    for (var frame = 0; frame < 16; frame++) {
      expect(
        _asset(tester),
        endsWith('run_${((frame + 1) % 16).toString().padLeft(2, '0')}.png'),
      );
      await tester.pump(const Duration(microseconds: 53751));
    }
  });

  testWidgets('ambient starts promptly and keeps moving for 90 seconds', (
    tester,
  ) async {
    const character = BalanceActivityCharacter(
      colors: AppColors.wellness,
      size: 36,
      animationMode: BalanceActivityAnimationMode.ambient,
    );
    await tester.pumpWidget(_app(character));
    await tester.pump(const Duration(milliseconds: 801));
    expect(_asset(tester), endsWith('dashboard_transition_idle_run_00_00.png'));
    await tester.pump(const Duration(milliseconds: 310));
    expect(_asset(tester), endsWith('dashboard_transition_idle_run_00_06.png'));
    await tester.pump(const Duration(milliseconds: 51));
    expect(_asset(tester), endsWith('dashboard_run_01.png'));
    final counts = <String, int>{'walk': 0, 'run': 0, 'idle': 0};
    var idleStreak = 0;
    var maxIdleStreak = 0;
    for (var tick = 0; tick < 4500; tick++) {
      await tester.pump(const Duration(milliseconds: 20));
      final keys = ['walk', 'run', 'idle'];
      final mode = keys.firstWhere(
        (mode) => find.byKey(ValueKey('activity-$mode')).evaluate().isNotEmpty,
      );
      counts[mode] = counts[mode]! + 1;
      expect(AmbientCharacterScheduler.activeSchedulers, 1);
      idleStreak = mode == 'idle' ? idleStreak + 1 : 0;
      if (idleStreak > maxIdleStreak) maxIdleStreak = idleStreak;
      if (tick % 100 == 0) {
        final beforeRebuild = _asset(tester);
        await tester.pumpWidget(
          _app(
            BalanceActivityCharacter(
              colors: AppColors.wellness,
              size: 36,
              travelWidth: 108 + tick.toDouble(),
              animationMode: BalanceActivityAnimationMode.ambient,
            ),
          ),
        );
        expect(_asset(tester), beforeRebuild);
      }
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    }
    // ignore: avoid_print
    print('AMBIENT_90S $counts maxIdleMs=${maxIdleStreak * 20}');
    expect(counts['walk'], 0);
    expect(counts['run']! / 4500, inInclusiveRange(.75, .85));
    expect(counts['idle']! / 4500, inInclusiveRange(.15, .25));
    expect(maxIdleStreak * 20, lessThan(3000));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'ambient pauses in background and hidden Dashboard, resumes once',
    (tester) async {
      Widget app(bool visible) => _app(
        TickerMode(
          enabled: visible,
          child: const BalanceActivityCharacter(
            colors: AppColors.wellness,
            size: 36,
            animationMode: BalanceActivityAnimationMode.ambient,
          ),
        ),
      );
      await tester.pumpWidget(app(true));
      await tester.pump(const Duration(milliseconds: 801));
      await tester.pump(const Duration(milliseconds: 400));
      expect(AmbientCharacterScheduler.activeSchedulers, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = _asset(tester);
      await tester.pump(const Duration(seconds: 60));
      expect(_asset(tester), paused);
      expect(AmbientCharacterScheduler.activeSchedulers, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(AmbientCharacterScheduler.activeSchedulers, 1);
      await tester.pumpWidget(app(false));
      expect(AmbientCharacterScheduler.activeSchedulers, 0);
      await tester.pumpWidget(app(true));
      expect(AmbientCharacterScheduler.activeSchedulers, 1);
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('activity-walk')), findsNothing);
      for (var i = 0; i < 20; i++) {
        final saved = _asset(tester);
        await tester.pumpWidget(app(false));
        await tester.pump(const Duration(seconds: 10));
        expect(_asset(tester), saved);
        await tester.pumpWidget(app(true));
        expect(_asset(tester), saved);
        expect(AmbientCharacterScheduler.activeSchedulers, 1);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(AmbientCharacterScheduler.activeSchedulers, 0);
    },
  );

  testWidgets(
    'background during acceleration resumes the same pose without catch-up',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const BalanceActivityCharacter(
            colors: AppColors.wellness,
            size: 36,
            animationMode: BalanceActivityAnimationMode.ambient,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 801));
      await tester.pump(const Duration(milliseconds: 150));
      final paused = _asset(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 60));
      expect(_asset(tester), paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(_asset(tester), paused);
      await tester.pump(const Duration(milliseconds: 211));
      expect(_asset(tester), endsWith('dashboard_run_01.png'));
      expect(AmbientCharacterScheduler.activeSchedulers, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('activity_transition_test preserves phase without crossfade', (
    tester,
  ) async {
    var mode = BalanceActivityAnimationMode.walk;
    late StateSetter setState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, update) {
            setState = update;
            return BalanceActivityCharacter(
              colors: AppColors.wellness,
              size: 68,
              animationMode: mode,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    expect(_asset(tester), endsWith('walk_06.png'));
    setState(() => mode = BalanceActivityAnimationMode.run);
    await tester.pump();
    expect(_asset(tester), endsWith('transition_walk_run_00.png'));
    await tester.pump(const Duration(milliseconds: 226));
    expect(_asset(tester), endsWith('transition_walk_run_02.png'));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pump(const Duration(milliseconds: 225));
    expect(_asset(tester), endsWith('run_08.png'));
    setState(() => mode = BalanceActivityAnimationMode.walk);
    await tester.pump();
    expect(_asset(tester), endsWith('transition_walk_run_04.png'));
    await tester.pump(const Duration(milliseconds: 226));
    expect(_asset(tester), endsWith('transition_walk_run_02.png'));
    await tester.pump(const Duration(milliseconds: 225));
    expect(_asset(tester), contains('walk_'));
  });

  testWidgets('idle run entry hands off to the adjacent production frame', (
    tester,
  ) async {
    Widget character(BalanceActivityAnimationMode mode) => _app(
      BalanceActivityCharacter(
        colors: AppColors.wellness,
        size: 36,
        animationMode: mode,
      ),
    );
    await tester.pumpWidget(character(BalanceActivityAnimationMode.idle));
    await tester.pumpWidget(character(BalanceActivityAnimationMode.run));
    for (var step = 0; step < 7; step++) {
      expect(
        _asset(tester),
        endsWith(
          'transition_idle_run_00_${step.toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pump(const Duration(microseconds: 51429));
    }
    expect(_asset(tester), endsWith('dashboard_run_01.png'));
    await tester.pump(const Duration(microseconds: 53750));
    expect(_asset(tester), endsWith('dashboard_run_02.png'));
  });

  testWidgets('run exit reaches either matched leg phase before deceleration', (
    tester,
  ) async {
    Widget character(BalanceActivityAnimationMode mode) => _app(
      BalanceActivityCharacter(
        colors: AppColors.wellness,
        size: 36,
        animationMode: mode,
      ),
    );
    for (final phase in [0, 8]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(character(BalanceActivityAnimationMode.run));
      await tester.pump(Duration(microseconds: ((phase + 15) % 16) * 53750));
      expect(
        _asset(tester),
        endsWith(
          'dashboard_run_${((phase + 15) % 16).toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pumpWidget(character(BalanceActivityAnimationMode.idle));
      expect(
        _asset(tester),
        endsWith(
          'dashboard_run_${((phase + 15) % 16).toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pump(const Duration(microseconds: 53751));
      expect(
        _asset(tester),
        endsWith(
          'transition_idle_run_${phase.toString().padLeft(2, '0')}_06.png',
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        _asset(tester),
        endsWith(
          'transition_idle_run_${phase.toString().padLeft(2, '0')}_00.png',
        ),
      );
      await tester.pump(const Duration(milliseconds: 51));
      expect(_asset(tester), endsWith('dashboard_idle.png'));
    }
  });

  testWidgets('idle to walk uses four authored transition states', (
    tester,
  ) async {
    var mode = BalanceActivityAnimationMode.idle;
    late StateSetter setState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, update) {
            setState = update;
            return BalanceActivityCharacter(
              colors: AppColors.wellness,
              size: 36,
              animationMode: mode,
            );
          },
        ),
      ),
    );
    setState(() => mode = BalanceActivityAnimationMode.walk);
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(
        frame == 0 ? Duration.zero : const Duration(milliseconds: 90),
      );
      expect(
        _asset(tester),
        endsWith(
          'dashboard_transition_idle_walk_${frame.toString().padLeft(2, '0')}.png',
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 91));
    expect(_asset(tester), contains('dashboard_walk_'));
  });

  testWidgets('walk to idle finishes the cycle before settling', (
    tester,
  ) async {
    var mode = BalanceActivityAnimationMode.walk;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return BalanceActivityCharacter(
              colors: AppColors.wellness,
              size: 36,
              animationMode: mode,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    expect(_asset(tester), endsWith('dashboard_walk_06.png'));
    update(() => mode = BalanceActivityAnimationMode.idle);
    await tester.pump();
    expect(_asset(tester), endsWith('dashboard_walk_06.png'));
    await tester.pump(const Duration(milliseconds: 160));
    expect(_asset(tester), endsWith('dashboard_walk_08.png'));
    await tester.pump(const Duration(milliseconds: 570));
    expect(_asset(tester), endsWith('dashboard_transition_idle_walk_03.png'));
    await tester.pump(const Duration(milliseconds: 91));
    expect(_asset(tester), endsWith('dashboard_transition_idle_walk_02.png'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(_asset(tester), endsWith('dashboard_transition_idle_walk_00.png'));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    await tester.pump(const Duration(milliseconds: 91));
    expect(_asset(tester), endsWith('dashboard_idle.png'));
  });

  testWidgets('activity_reduce_motion_test', (tester) async {
    await tester.pumpWidget(
      _app(
        const BalanceActivityCharacter(
          colors: AppColors.wellness,
          animationMode: BalanceActivityAnimationMode.run,
        ),
        reduceMotion: true,
      ),
    );
    final asset = _asset(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_asset(tester), asset);
    expect(
      find.byKey(const ValueKey('activityTicker-stopped')),
      findsOneWidget,
    );
  });

  for (final testCase in [
    ('dashboard_character_test', 36.0, 'dashboard_run_'),
    ('steps_character_test', 68.0, 'run_'),
  ]) {
    testWidgets(testCase.$1, (tester) async {
      await tester.pumpWidget(
        _app(
          BalanceActivityCharacter(
            colors: AppColors.wellness,
            size: testCase.$2,
            animationMode: BalanceActivityAnimationMode.run,
          ),
        ),
      );
      expect(_asset(tester), contains(testCase.$3));
    });
  }
}
