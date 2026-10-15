import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class BalanceMotion {
  static const tap = Duration(milliseconds: 140);
  static const micro = Duration(milliseconds: 220);
  static const card = Duration(milliseconds: 300);
  static const sheet = Duration(milliseconds: 360);
  static const screen = Duration(milliseconds: 420);
  static const glass = Duration(milliseconds: 720);

  static const standard = Cubic(.22, .61, .36, 1);
  static const emphasized = Cubic(.25, .72, .25, 1);

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> achievement() => HapticFeedback.mediumImpact();
}
