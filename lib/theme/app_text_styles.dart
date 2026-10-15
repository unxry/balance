import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography ported from the design handoff:
/// - Fraunces: display / numbers
/// - Inter: UI text / body
/// - JetBrains Mono: labels / meta (uppercase, tracked)
class AppText {
  final AppColors c;
  AppText(this.c);

  TextStyle fraunces({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -0.02,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontFamilyFallback: const ['Inter'],
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing * size,
    color: color ?? c.fg,
    height: height,
  );

  TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = -0.01,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing * size,
    color: color ?? c.fg,
    height: height,
  );

  TextStyle mono({
    double size = 10,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0.14,
    Color? color,
  }) => TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing * size,
    color: color ?? c.muted,
  );
}
