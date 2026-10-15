import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/premium_motion.dart';
import 'package:flutter_app/widgets/realistic_water.dart';

void main() => runApp(const WaterRuntimePreviewApp());

class WaterRuntimePreviewApp extends StatelessWidget {
  const WaterRuntimePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.wellness.page,
      ),
      home: const WaterRuntimePreview(),
    );
  }
}

class WaterRuntimePreview extends StatefulWidget {
  const WaterRuntimePreview({super.key});

  @override
  State<WaterRuntimePreview> createState() => _WaterRuntimePreviewState();
}

class _WaterRuntimePreviewState extends State<WaterRuntimePreview> {
  final List<Timer> _timers = [];
  double _valueMl = 150;
  String _stage = '150 мл · PURE IDLE 0–15s';

  @override
  void initState() {
    super.initState();
    _schedulePreview();
  }

  void _schedulePreview() {
    _timers
      ..add(
        Timer(
          const Duration(milliseconds: 15200),
          () => _setWater(400, 'INTERRUPTED ADD · 150 → 400 мл'),
        ),
      )
      ..add(
        Timer(
          const Duration(milliseconds: 15800),
          () => _setWater(650, 'INTERRUPTED ADD · 400 → 650 мл'),
        ),
      )
      ..add(
        Timer(
          const Duration(milliseconds: 19000),
          () => setState(() => _stage = '650 мл · SETTLED'),
        ),
      )
      ..add(
        Timer(
          const Duration(milliseconds: 20200),
          () => _setWater(400, 'INTERRUPTED REMOVE · 650 → 400 мл'),
        ),
      )
      ..add(
        Timer(
          const Duration(milliseconds: 20800),
          () => _setWater(150, 'INTERRUPTED REMOVE · 400 → 150 мл'),
        ),
      )
      ..add(
        Timer(const Duration(milliseconds: 24200), () {
          if (mounted) setState(() => _stage = '150 мл · SETTLED + IDLE');
        }),
      );
  }

  void _setWater(double value, String stage) {
    if (!mounted) return;
    setState(() {
      _valueMl = value;
      _stage = stage;
    });
  }

  void _addWater() =>
      _setWater((_valueMl + 250).clamp(0, 2500).toDouble(), 'TAP +250 мл');

  void _decreaseWater() => _setWater(
    (_valueMl - 1000).clamp(0, 2500).toDouble(),
    'DECREASE −1000 мл',
  );

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.wellness;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4EDDE), Color(0xFFE5DCC5)],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BALANCE · WATER RUNTIME PROOF',
                  style: TextStyle(
                    color: Color(0xFF3A352D),
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    letterSpacing: 2.1,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _stage,
                    key: ValueKey(_stage),
                    style: const TextStyle(
                      color: Color(0xFF8A8272),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 330,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .8),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F3B3326),
                        blurRadius: 34,
                        offset: Offset(0, 17),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RealisticWaterLayer(
                          valueMl: _valueMl,
                          goalMl: 2500,
                          colors: colors,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'ВОДА',
                                  style: TextStyle(
                                    color: Color(0xFF1C1A17),
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 13,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const Spacer(),
                                _RoundControl(
                                  icon: Icons.remove_rounded,
                                  onTap: _decreaseWater,
                                ),
                                const SizedBox(width: 10),
                                _RoundControl(
                                  icon: Icons.add_rounded,
                                  onTap: _addWater,
                                ),
                              ],
                            ),
                            const Spacer(),
                            BalanceAnimatedNumber(
                              value: _valueMl,
                              duration: const Duration(milliseconds: 740),
                              formatter: (value) =>
                                  '${value.round()} / 2500 мл',
                              style: const TextStyle(
                                color: Color(0xFF1C1A17),
                                fontFamily: 'Fraunces',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCCFFFAEB),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            WaterProgressIndicators(
                              progress: _valueMl / 2500,
                              activeColor: colors.accent,
                              trackColor: colors.track.withValues(alpha: .84),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '15s PURE IDLE · INTERRUPTED ADD/REMOVE · 12s FINAL IDLE',
                    style: TextStyle(
                      color: Color(0xFF3A352D),
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.wellness.card.withValues(alpha: .84),
      shape: const CircleBorder(side: BorderSide(color: Color(0xD9FFFFFF))),
      elevation: 3,
      shadowColor: const Color(0x243B3326),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.wellness.fg, size: 23),
        ),
      ),
    );
  }
}
