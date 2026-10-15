import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MacroEnergyBreakdown {
  final double proteinCalories;
  final double fatCalories;
  final double carbCalories;
  final double totalCalories;
  final double calorieProgress;
  final double overGoalProgress;

  const MacroEnergyBreakdown({
    required this.proteinCalories,
    required this.fatCalories,
    required this.carbCalories,
    required this.totalCalories,
    required this.calorieProgress,
    required this.overGoalProgress,
  });

  factory MacroEnergyBreakdown.calculate({
    required double proteinG,
    required double fatG,
    required double carbsG,
    required int calories,
    required int calorieGoal,
  }) {
    final protein = math.max(0.0, proteinG) * 4;
    final fat = math.max(0.0, fatG) * 9;
    final carbs = math.max(0.0, carbsG) * 4;
    final total = protein + fat + carbs;
    final ratio = calorieGoal <= 0 ? 0.0 : calories / calorieGoal;
    return MacroEnergyBreakdown(
      proteinCalories: protein,
      fatCalories: fat,
      carbCalories: carbs,
      totalCalories: total,
      calorieProgress: ratio.clamp(0.0, 1.0),
      overGoalProgress: math.max(0.0, ratio - 1).clamp(0.0, 1.0),
    );
  }

  List<double> get shares => totalCalories <= 0
      ? const [0, 0, 0]
      : [
          proteinCalories / totalCalories,
          fatCalories / totalCalories,
          carbCalories / totalCalories,
        ];
}

class AnimatedMacroRing extends StatefulWidget {
  final MacroEnergyBreakdown breakdown;
  final AppColors colors;
  final String animationKey;
  final double strokeWidth;
  final Widget child;

  const AnimatedMacroRing({
    super.key,
    required this.breakdown,
    required this.colors,
    required this.animationKey,
    required this.child,
    this.strokeWidth = 14,
  });

  @override
  State<AnimatedMacroRing> createState() => _AnimatedMacroRingState();
}

class _AnimatedMacroRingState extends State<AnimatedMacroRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animate());
  }

  @override
  void didUpdateWidget(covariant AnimatedMacroRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationKey != widget.animationKey) _animate();
  }

  void _animate() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) {
      final value = Curves.easeOutCubic.transform(_controller.value);
      return CustomPaint(
        key: const ValueKey('macroCalorieRing'),
        painter: _MacroRingPainter(
          breakdown: widget.breakdown,
          colors: widget.colors,
          animationValue: value,
          strokeWidth: widget.strokeWidth,
        ),
        child: widget.child,
      );
    },
  );
}

class _MacroRingPainter extends CustomPainter {
  final MacroEnergyBreakdown breakdown;
  final AppColors colors;
  final double animationValue;
  final double strokeWidth;

  const _MacroRingPainter({
    required this.breakdown,
    required this.colors,
    required this.animationValue,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = colors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final shares = breakdown.shares;
    final ringColors = [colors.accent, colors.accent2, colors.macroCarb];
    var start = -math.pi / 2;
    final totalSweep = math.pi * 2 * breakdown.calorieProgress * animationValue;
    const gap = .035;
    for (var i = 0; i < shares.length; i++) {
      final rawSweep = totalSweep * shares[i];
      if (rawSweep <= 0) continue;
      final sweep = math.max(0.0, rawSweep - gap);
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = ringColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += rawSweep;
    }
    if (breakdown.overGoalProgress > 0) {
      final outerRadius = radius + strokeWidth * .72;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        math.pi * 2 * breakdown.overGoalProgress * animationValue,
        false,
        Paint()
          ..color = colors.accent2.withValues(alpha: .68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.breakdown != breakdown ||
      oldDelegate.colors != colors;
}
