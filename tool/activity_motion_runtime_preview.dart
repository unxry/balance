import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/theme/app_text_styles.dart';
import 'package:flutter_app/widgets/common.dart';
import 'package:flutter_app/widgets/premium_motion.dart';

void main() => runApp(const _ActivityMotionPreview());

class _ActivityMotionPreview extends StatefulWidget {
  const _ActivityMotionPreview();

  @override
  State<_ActivityMotionPreview> createState() => _ActivityMotionPreviewState();
}

class _ActivityMotionPreviewState extends State<_ActivityMotionPreview> {
  static const _reviewTransitions = bool.fromEnvironment('WALK_TRANSITIONS');
  var _mode = _reviewTransitions
      ? BalanceActivityAnimationMode.idle
      : BalanceActivityAnimationMode.walk;
  final _reviewTimers = <Timer>[];

  @override
  void initState() {
    super.initState();
    if (_reviewTransitions) {
      for (final entry in [
        (2, BalanceActivityAnimationMode.walk),
        (10, BalanceActivityAnimationMode.idle),
        (14, BalanceActivityAnimationMode.walk),
      ]) {
        _reviewTimers.add(
          Timer(Duration(seconds: entry.$1), () {
            if (mounted) setState(() => _mode = entry.$2);
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final timer in _reviewTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.wellness;
    final text = AppText(colors);
    return AppColorsScope(
      colors: colors,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: colors.surface,
          fontFamily: 'Inter',
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 164,
              height: 160,
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const MonoLabel('ШАГИ'),
                        const Spacer(),
                        BalanceActivityCharacter(
                          colors: colors,
                          size: 36,
                          travelWidth: 58,
                          animationMode: _mode,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '7 842',
                      style: text.fraunces(size: 26, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'сегодня',
                      style: text.mono(size: 9, color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
