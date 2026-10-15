import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ambient_character_scheduler.dart';
import '../theme/app_colors.dart';
import '../theme/balance_motion.dart';

class BalanceAnimatedValue extends StatelessWidget {
  const BalanceAnimatedValue({
    super.key,
    required this.value,
    required this.style,
    this.textAlign,
  });

  final String value;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: BalanceMotion.resolve(context, BalanceMotion.micro),
    switchInCurve: BalanceMotion.standard,
    switchOutCurve: BalanceMotion.standard,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: Text(
      value,
      key: ValueKey(value),
      textAlign: textAlign,
      style: style,
    ),
  );
}

class BalanceAnimatedNumber extends StatefulWidget {
  const BalanceAnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.duration = const Duration(milliseconds: 340),
    this.textAlign,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  State<BalanceAnimatedNumber> createState() => _BalanceAnimatedNumberState();
}

class BalanceSparkleField extends StatefulWidget {
  const BalanceSparkleField({
    super.key,
    required this.colors,
    this.previewProgress,
  });

  final AppColors colors;
  final double? previewProgress;

  @override
  State<BalanceSparkleField> createState() => _BalanceSparkleFieldState();
}

enum _SparkleShape { point, diamond, fourPoint }

class _SparkleSpec {
  const _SparkleSpec(
    this.x,
    this.y,
    this.phase,
    this.size,
    this.durationMs,
    this.driftX,
    this.driftY,
    this.shape,
    this.colorIndex, {
    this.depth = 1,
  });

  final double x;
  final double y;
  final double phase;
  final double size;
  final int durationMs;
  final double driftX;
  final double driftY;
  final _SparkleShape shape;
  final int colorIndex;
  final double depth;
}

class _BalanceSparkleFieldState extends State<BalanceSparkleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 10),
  );
  bool _reduceMotion = false;

  static const _particles = <_SparkleSpec>[
    _SparkleSpec(.49, .18, .07, 3.2, 4100, 2.4, -3.0, _SparkleShape.point, 2),
    _SparkleSpec(.62, .26, .61, 5.2, 5200, -3.1, 2.2, _SparkleShape.diamond, 0),
    _SparkleSpec(.76, .22, .28, 3.4, 3400, 2.0, 3.4, _SparkleShape.point, 1),
    _SparkleSpec(
      .91,
      .29,
      .83,
      6.6,
      6000,
      -2.8,
      -3.6,
      _SparkleShape.fourPoint,
      0,
    ),
    _SparkleSpec(
      .55,
      .39,
      .44,
      3.0,
      2800,
      2.6,
      2.0,
      _SparkleShape.point,
      1,
      depth: .62,
    ),
    _SparkleSpec(.69, .43, .14, 4.8, 4100, -3.4, 2.5, _SparkleShape.diamond, 2),
    _SparkleSpec(.84, .41, .72, 3.1, 5200, 2.2, -4.1, _SparkleShape.point, 0),
    _SparkleSpec(
      .95,
      .49,
      .36,
      4.6,
      3400,
      -2.0,
      2.8,
      _SparkleShape.diamond,
      1,
      depth: .72,
    ),
    _SparkleSpec(
      .59,
      .57,
      .91,
      3.0,
      6000,
      3.0,
      -2.0,
      _SparkleShape.point,
      0,
      depth: .55,
    ),
    _SparkleSpec(
      .74,
      .58,
      .52,
      6.2,
      5200,
      -3.8,
      3.0,
      _SparkleShape.fourPoint,
      2,
    ),
    _SparkleSpec(.89, .62, .19, 3.5, 4100, 2.5, 4.4, _SparkleShape.point, 1),
    _SparkleSpec(
      .97,
      .70,
      .67,
      4.8,
      2800,
      -2.1,
      -2.5,
      _SparkleShape.diamond,
      0,
      depth: .62,
    ),
    _SparkleSpec(
      .54,
      .76,
      .31,
      3.1,
      3400,
      2.8,
      -3.2,
      _SparkleShape.point,
      1,
      depth: .48,
    ),
    _SparkleSpec(
      .68,
      .82,
      .77,
      4.5,
      6000,
      -2.4,
      3.6,
      _SparkleShape.diamond,
      0,
      depth: .58,
    ),
    _SparkleSpec(.82, .79, .03, 3.0, 4100, 3.2, -2.4, _SparkleShape.point, 2),
    _SparkleSpec(
      .93,
      .88,
      .48,
      6.0,
      5200,
      -3.0,
      -3.8,
      _SparkleShape.fourPoint,
      0,
      depth: .72,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant BalanceSparkleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewProgress != widget.previewProgress) _syncMotion();
  }

  void _syncMotion() {
    if (_reduceMotion || widget.previewProgress != null) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          key: const ValueKey('balanceSparkleField'),
          fit: StackFit.expand,
          children: [
            for (var index = 0; index < _particles.length; index++)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final item = _particles[index];
                  final elapsedMs =
                      (widget.previewProgress ?? _controller.value) * 600000;
                  final phase = _reduceMotion
                      ? item.phase
                      : (elapsedMs / item.durationMs + item.phase) % 1;
                  final brightness = _sparkleBrightness(phase) * item.depth;
                  final driftPhase = phase * math.pi * 2;
                  final driftX = _reduceMotion
                      ? 0.0
                      : math.sin(driftPhase) * item.driftX;
                  final driftY = _reduceMotion
                      ? 0.0
                      : math.sin(driftPhase * .83 + item.phase * math.pi) *
                            item.driftY;
                  final particleColor = switch (item.colorIndex) {
                    0 => widget.colors.champagne,
                    1 => widget.colors.accent,
                    _ => widget.colors.accent3,
                  };
                  return Align(
                    alignment: Alignment(item.x * 2 - 1, item.y * 2 - 1),
                    child: Transform.translate(
                      offset: Offset(driftX, driftY),
                      child: Transform.scale(
                        scale: .92 + brightness * .12,
                        child: Opacity(
                          opacity: brightness.clamp(.08, .65),
                          child: SizedBox.square(
                            key: ValueKey('adviceSparkle-$index'),
                            dimension: item.size,
                            child: CustomPaint(
                              painter: _SparklePainter(
                                color: particleColor,
                                shape: item.shape,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

double _sparkleBrightness(double phase) {
  const stops = [0.0, .22, .48, .72, 1.0];
  const values = [.15, .35, .65, .30, .15];
  for (var index = 0; index < stops.length - 1; index++) {
    if (phase <= stops[index + 1]) {
      final local = (phase - stops[index]) / (stops[index + 1] - stops[index]);
      final eased = .5 - .5 * math.cos(local * math.pi);
      return values[index] + (values[index + 1] - values[index]) * eased;
    }
  }
  return values.last;
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color, required this.shape});

  final Color color;
  final _SparkleShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (shape == _SparkleShape.point) {
      canvas.drawCircle(
        center,
        radius * .55,
        Paint()
          ..color = color.withValues(alpha: .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .75),
      );
      canvas.drawCircle(center, radius * .32, Paint()..color = color);
      return;
    }
    final horizontal = shape == _SparkleShape.diamond ? radius * .64 : radius;
    final shoulder = shape == _SparkleShape.diamond
        ? radius * .32
        : radius * .16;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx,
        center.dy - shoulder,
        center.dx + horizontal,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + shoulder,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + shoulder,
        center.dx - horizontal,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy - shoulder,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .9),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shape != shape;
}

class _BalanceAnimatedNumberState extends State<BalanceAnimatedNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..value = 1;
  late double _from = widget.value;
  late double _to = widget.value;

  @override
  void didUpdateWidget(covariant BalanceAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _from = _currentValue;
    _to = widget.value;
    _controller
      ..duration = widget.duration
      ..forward(from: 0);
  }

  double get _currentValue =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(
          widget.formatter(widget.value),
          key: ValueKey(widget.formatter(widget.value)),
          textAlign: widget.textAlign,
          style: widget.style,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final direction = (_to - _from).sign;
        final remaining = 1 - Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: .78 + .22 * (1 - remaining),
          child: Transform.translate(
            offset: Offset(0, direction * 6 * remaining),
            child: Text(
              widget.formatter(_currentValue),
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;
  final String? semanticsLabel;
  final String? semanticsValue;
  final String? semanticsHint;
  final bool? selected;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.pressedScale = .975,
    this.semanticsLabel,
    this.semanticsValue,
    this.semanticsHint,
    this.selected,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      hint: widget.semanticsHint,
      child: widget.semanticsLabel == null
          ? _gestureChild(reduceMotion)
          : ExcludeSemantics(child: _gestureChild(reduceMotion)),
    );
  }

  Widget _gestureChild(bool reduceMotion) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onTapDown: widget.onTap == null
        ? null
        : (_) => setState(() => _pressed = true),
    onTapCancel: widget.onTap == null
        ? null
        : () => setState(() => _pressed = false),
    onTapUp: widget.onTap == null
        ? null
        : (_) => setState(() => _pressed = false),
    child: AnimatedOpacity(
      opacity: _pressed && reduceMotion ? .86 : 1,
      duration: BalanceMotion.resolve(context, BalanceMotion.tap),
      curve: BalanceMotion.standard,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
        duration: BalanceMotion.resolve(context, BalanceMotion.tap),
        curve: BalanceMotion.standard,
        child: widget.child,
      ),
    ),
  );
}

class PremiumPulse extends StatefulWidget {
  final Widget child;
  final bool active;
  final double maxScale;

  const PremiumPulse({
    super.key,
    required this.child,
    this.active = true,
    this.maxScale = 1.1,
  });

  @override
  State<PremiumPulse> createState() => _PremiumPulseState();
}

class _PremiumPulseState extends State<PremiumPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PremiumPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final enabled =
        widget.active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_controller.isAnimating) {
      _controller.forward(from: 0);
    } else if (!enabled) {
      _controller.stop();
      _controller.value = 0;
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
    child: widget.child,
    builder: (_, child) {
      final wave = (1 - math.cos(_controller.value * math.pi * 2)) / 2;
      return Transform.scale(
        scale: 1 + (widget.maxScale - 1) * wave,
        child: child,
      );
    },
  );
}

class BalancePulsePoint extends StatefulWidget {
  const BalancePulsePoint({super.key, required this.colors, this.size = 28});

  final AppColors colors;
  final double size;

  @override
  State<BalancePulsePoint> createState() => _BalancePulsePointState();
}

class _BalancePulsePointState extends State<BalancePulsePoint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: const ValueKey('balancePulsePoint'),
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final wave = (1 - math.cos(_controller.value * math.pi * 2)) / 2;
        return Stack(
          key: ValueKey(
            'balancePulseTicker-${_controller.isAnimating ? 'active' : 'stopped'}',
          ),
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + .35 * wave,
              child: Opacity(
                opacity: .15 - .12 * wave,
                child: Container(
                  width: widget.size * .72,
                  height: widget.size * .72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.colors.accent,
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 1 + .05 * wave,
              child: Container(
                width: widget.size * .34,
                height: widget.size * .34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.colors.accent,
                  border: Border.all(color: widget.colors.card, width: 1.5),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

enum BalanceActivityAnimationMode { idle, walk, run, walkRunCycle, ambient }

enum BalanceActivityPose {
  idle,
  walkContact,
  walkDown,
  walkPassing,
  walkUp,
  walkOppositeContact,
  walkOppositeDown,
  walkOppositePassing,
  walkOppositeUp,
  runContact,
  runDown,
  runFlight,
  runRecovery,
  runOppositeContact,
  runOppositeDown,
  runOppositeFlight,
  runOppositeRecovery,
}

/// A compact wayfinding-style human rig shared by Dashboard and Steps.
class BalanceActivityCharacter extends StatefulWidget {
  const BalanceActivityCharacter({
    super.key,
    required this.colors,
    this.size = 42,
    this.travelWidth = 108,
    this.animationMode = BalanceActivityAnimationMode.walkRunCycle,
    this.isVisible = true,
    this.reduceMotion = false,
    this.previewPose,
    this.previewProgress,
  });

  final AppColors colors;
  final double size;
  final double travelWidth;
  final BalanceActivityAnimationMode animationMode;
  final bool isVisible;
  final bool reduceMotion;
  final BalanceActivityPose? previewPose;
  final double? previewProgress;

  @override
  State<BalanceActivityCharacter> createState() =>
      _BalanceActivityCharacterState();
}

class _BalanceActivityCharacterState extends State<BalanceActivityCharacter>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final AnimationController _transitionController;
  late final AmbientCharacterScheduler _ambient;
  late BalanceActivityAnimationMode _displayMode;
  BalanceActivityAnimationMode? _transitionFrom;
  BalanceActivityAnimationMode? _transitionTo;
  double _transitionStartPhase = 0;
  double _walkFinishMilliseconds = 0;
  double _runFinishMilliseconds = 0;
  int _runBridgeFrame = 0;
  bool _preloaded = false;
  bool _appActive = true;

  bool get _scheduledAmbient =>
      widget.animationMode == BalanceActivityAnimationMode.ambient &&
      widget.previewProgress == null &&
      widget.previewPose == null;
  BalanceActivityAnimationMode get _mode => _scheduledAmbient
      ? switch (_ambient.gait) {
          AmbientGait.idle => BalanceActivityAnimationMode.idle,
          AmbientGait.walk => BalanceActivityAnimationMode.walk,
          AmbientGait.run => BalanceActivityAnimationMode.run,
        }
      : widget.animationMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appActive =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _ambient = AmbientCharacterScheduler()..addListener(_ambientChanged);
    _displayMode = _mode;
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(_mode),
    );
    _transitionController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 360),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _transitionTo != null) {
            _finishTransition();
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preloaded) {
      _preloaded = true;
      for (final asset in _activityAssets(widget.size <= 42)) {
        precacheImage(AssetImage(asset), context);
      }
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _sync();
  }

  void _ambientChanged() {
    if (!mounted || !_scheduledAmbient) return;
    _beginTransition(_displayMode, _mode);
  }

  @override
  void didUpdateWidget(covariant BalanceActivityCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationMode != widget.animationMode) {
      final previous =
          oldWidget.animationMode == BalanceActivityAnimationMode.ambient
          ? switch (_ambient.gait) {
              AmbientGait.idle => BalanceActivityAnimationMode.idle,
              AmbientGait.walk => BalanceActivityAnimationMode.walk,
              AmbientGait.run => BalanceActivityAnimationMode.run,
            }
          : oldWidget.animationMode;
      _beginTransition(previous, _mode);
    }
    _sync();
  }

  void _beginTransition(
    BalanceActivityAnimationMode from,
    BalanceActivityAnimationMode to,
  ) {
    _displayMode = to;
    _transitionStartPhase = _controller.value;
    _transitionFrom = from;
    _transitionTo = to;
    _controller.stop();
    _controller.duration = _durationFor(to);
    _walkFinishMilliseconds =
        from == BalanceActivityAnimationMode.walk &&
            to == BalanceActivityAnimationMode.idle
        ? (1 - _transitionStartPhase) * 1250
        : 0;
    _runFinishMilliseconds = 0;
    if (from == BalanceActivityAnimationMode.run &&
        to == BalanceActivityAnimationMode.idle) {
      final phase = _transitionStartPhase;
      _runBridgeFrame = phase == 0 || phase > 8 / 16 ? 0 : 8;
      _runFinishMilliseconds = ((_runBridgeFrame / 16 - phase) % 1) * 860;
    } else if (from == BalanceActivityAnimationMode.idle &&
        to == BalanceActivityAnimationMode.run) {
      _runBridgeFrame = 0;
    }
    _transitionController
      ..stop()
      ..duration =
          {from, to}.contains(BalanceActivityAnimationMode.idle) &&
              {from, to}.contains(BalanceActivityAnimationMode.run)
          ? Duration(
              milliseconds:
                  (from == BalanceActivityAnimationMode.run
                          ? 400 + _runFinishMilliseconds
                          : 360)
                      .round(),
            )
          : from == BalanceActivityAnimationMode.idle ||
                to == BalanceActivityAnimationMode.idle
          ? Duration(milliseconds: 360 + _walkFinishMilliseconds.round())
          : const Duration(milliseconds: 450)
      ..value = 0;
    setState(() {});
    _sync();
  }

  void _finishTransition() {
    final startingWalk =
        _transitionFrom == BalanceActivityAnimationMode.idle &&
        _transitionTo == BalanceActivityAnimationMode.walk;
    final startingRun =
        _transitionFrom == BalanceActivityAnimationMode.idle &&
        _transitionTo == BalanceActivityAnimationMode.run;
    final stoppingRun =
        _transitionFrom == BalanceActivityAnimationMode.run &&
        _transitionTo == BalanceActivityAnimationMode.idle;
    final targetFrames = _transitionTo == BalanceActivityAnimationMode.idle
        ? 8
        : 16;
    setState(() {
      _transitionFrom = null;
      _transitionTo = null;
      _controller.value = startingRun
          ? (_runBridgeFrame + 1) / 16
          : stoppingRun
          ? 0
          : startingWalk
          ? 1 / 16
          : (_transitionStartPhase + 2 / targetFrames) % 1;
    });
    if (_scheduledAmbient) _ambient.transitionFinished();
    _sync();
  }

  Duration _durationFor(BalanceActivityAnimationMode mode) => switch (mode) {
    BalanceActivityAnimationMode.walk => const Duration(milliseconds: 1250),
    BalanceActivityAnimationMode.run => const Duration(milliseconds: 860),
    BalanceActivityAnimationMode.walkRunCycle => const Duration(
      milliseconds: 6550,
    ),
    BalanceActivityAnimationMode.ambient => const Duration(seconds: 30),
    BalanceActivityAnimationMode.idle => const Duration(milliseconds: 3200),
  };

  void _sync() {
    final animate =
        _appActive &&
        widget.isVisible &&
        widget.previewPose == null &&
        widget.previewProgress == null &&
        !widget.reduceMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _ambient.setActive(animate && _scheduledAmbient);
    if (!animate) {
      _controller.stop(canceled: false);
      _transitionController.stop(canceled: false);
    } else if (_transitionTo != null) {
      if (!_transitionController.isAnimating) _transitionController.forward();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ambient.dispose();
    _controller.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('balanceActivityCharacter'),
    width: widget.travelWidth,
    height: widget.size,
    child: AnimatedBuilder(
      animation: Listenable.merge([_controller, _transitionController]),
      builder: (_, __) {
        final progress = (widget.previewProgress ?? _controller.value).clamp(
          0.0,
          1.0,
        );
        final preview = widget.previewPose;
        final cycleMilliseconds = progress * 6550;
        final ambientMilliseconds = progress * 30000;
        final gaitPhase = preview != null
            ? _previewPhase(preview)
            : switch (_mode) {
                BalanceActivityAnimationMode.idle => 0.0,
                BalanceActivityAnimationMode.walk ||
                BalanceActivityAnimationMode.run => progress % 1,
                BalanceActivityAnimationMode.walkRunCycle =>
                  cycleMilliseconds < 3750
                      ? (cycleMilliseconds / 1250) % 1
                      : ((cycleMilliseconds - 3750) / 700) % 1,
                BalanceActivityAnimationMode.ambient =>
                  ambientMilliseconds < 5000
                      ? ambientMilliseconds / 5000
                      : ambientMilliseconds < 12500
                      ? ((math.max(0, ambientMilliseconds - 5360) / 1250) +
                                1 / 16) %
                            1
                      : ambientMilliseconds < 18100
                      ? ((ambientMilliseconds - 12500) / 700) % 1
                      : ambientMilliseconds < 25600
                      ? ((ambientMilliseconds - 18100) / 1250) % 1
                      : (ambientMilliseconds - 25600) / 4400,
              };
        var mode =
            preview == BalanceActivityPose.idle ||
                (preview == null && _mode == BalanceActivityAnimationMode.idle)
            ? BalanceActivityAnimationMode.idle
            : preview != null
            ? (_previewRunBlend(preview) >= .5
                  ? BalanceActivityAnimationMode.run
                  : BalanceActivityAnimationMode.walk)
            : _mode == BalanceActivityAnimationMode.walkRunCycle
            ? (cycleMilliseconds >= 3750
                  ? BalanceActivityAnimationMode.run
                  : BalanceActivityAnimationMode.walk)
            : _mode == BalanceActivityAnimationMode.ambient
            ? ambientMilliseconds < 5000
                  ? BalanceActivityAnimationMode.idle
                  : ambientMilliseconds < 12500
                  ? BalanceActivityAnimationMode.walk
                  : ambientMilliseconds < 18100
                  ? BalanceActivityAnimationMode.run
                  : ambientMilliseconds < 25600
                  ? BalanceActivityAnimationMode.walk
                  : BalanceActivityAnimationMode.idle
            : _mode;
        final compact = widget.size <= 42;
        var frameCount =
            mode == BalanceActivityAnimationMode.walk ||
                mode == BalanceActivityAnimationMode.run
            ? 16
            : 8;
        var frame = mode == BalanceActivityAnimationMode.idle
            ? 0
            : (gaitPhase * frameCount).floor() % frameCount;
        String? transitionAsset;
        if ((_transitionTo != null) && preview == null) {
          final rawFrom = _transitionFrom ?? mode;
          final rawTo = _transitionTo ?? mode;
          final from = rawFrom == BalanceActivityAnimationMode.walkRunCycle
              ? BalanceActivityAnimationMode.walk
              : rawFrom;
          final to = rawTo == BalanceActivityAnimationMode.walkRunCycle
              ? BalanceActivityAnimationMode.walk
              : rawTo;
          final prefix = compact ? 'dashboard_' : '';
          if ({from, to}.contains(BalanceActivityAnimationMode.idle) &&
              {from, to}.contains(BalanceActivityAnimationMode.run)) {
            final exiting = from == BalanceActivityAnimationMode.run;
            final elapsed =
                _transitionController.value *
                _transitionController.duration!.inMilliseconds;
            if (exiting && elapsed < _runFinishMilliseconds) {
              mode = BalanceActivityAnimationMode.run;
              frame =
                  ((_transitionStartPhase + elapsed / 860) * 16).floor() % 16;
            } else {
              final bridge = exiting
                  ? ((elapsed - _runFinishMilliseconds) / 400).clamp(0.0, 1.0)
                  : _transitionController.value;
              final step = math.min(6, (bridge * 7).floor());
              final pose = exiting ? 6 - step : step;
              transitionAsset =
                  'assets/character/${prefix}transition_idle_run_${_runBridgeFrame.toString().padLeft(2, '0')}_${pose.toString().padLeft(2, '0')}.png';
              mode = bridge < .5 ? from : to;
              frame = pose;
            }
          } else if ({from, to}.contains(BalanceActivityAnimationMode.idle) &&
              {from, to}.contains(BalanceActivityAnimationMode.walk)) {
            const count = 4;
            final elapsed =
                _transitionController.value *
                _transitionController.duration!.inMilliseconds;
            final finishingWalk =
                from == BalanceActivityAnimationMode.walk &&
                elapsed < _walkFinishMilliseconds;
            final transitionProgress = from == BalanceActivityAnimationMode.walk
                ? ((elapsed - _walkFinishMilliseconds) / 360).clamp(0.0, 1.0)
                : _transitionController.value;
            var step = math.min(
              count - 1,
              (transitionProgress * count).floor(),
            );
            if (from == BalanceActivityAnimationMode.walk) {
              step = count - 1 - step;
            }
            if (finishingWalk) {
              mode = BalanceActivityAnimationMode.walk;
              frame =
                  ((_transitionStartPhase + elapsed / 1250) * 16).floor() % 16;
            } else {
              transitionAsset =
                  'assets/character/${prefix}transition_idle_walk_${step.toString().padLeft(2, '0')}.png';
              mode = transitionProgress < .5 ? from : to;
              frame = step;
            }
          } else if ({from, to}.contains(BalanceActivityAnimationMode.walk) &&
              {from, to}.contains(BalanceActivityAnimationMode.run)) {
            const count = 5;
            var step = math.min(
              count - 1,
              (_transitionController.value * count).floor(),
            );
            if (from == BalanceActivityAnimationMode.run) {
              step = count - 1 - step;
            }
            transitionAsset =
                'assets/character/${prefix}transition_walk_run_${step.toString().padLeft(2, '0')}.png';
            mode = _transitionController.value < .5 ? from : to;
            frame = step;
          } else {
            final step = math.min(3, (_transitionController.value * 4).floor());
            mode = step < 2 ? from : to;
            frameCount =
                mode == BalanceActivityAnimationMode.walk ||
                    mode == BalanceActivityAnimationMode.run
                ? 16
                : 8;
            frame =
                ((_transitionStartPhase * frameCount).floor() +
                    (step > 0 ? step - 1 : 0)) %
                frameCount;
          }
        }
        if (!(_transitionTo != null) &&
            preview == null &&
            _mode == BalanceActivityAnimationMode.ambient) {
          final enteringWalk =
              ambientMilliseconds >= 5000 && ambientMilliseconds < 5360;
          final leavingWalk =
              ambientMilliseconds >= 25600 && ambientMilliseconds < 25960;
          if (enteringWalk || leavingWalk) {
            final elapsed = ambientMilliseconds - (enteringWalk ? 5000 : 25600);
            var step = math.min(3, (elapsed / 90).floor());
            if (leavingWalk) step = 3 - step;
            transitionAsset =
                'assets/character/${compact ? 'dashboard_' : ''}transition_idle_walk_${step.toString().padLeft(2, '0')}.png';
            mode = (enteringWalk ? elapsed < 180 : elapsed >= 180)
                ? BalanceActivityAnimationMode.idle
                : BalanceActivityAnimationMode.walk;
            frame = step;
          }
        }
        final asset =
            transitionAsset ?? _activityAsset(mode, frame, compact: compact);
        final idleShift =
            mode == BalanceActivityAnimationMode.idle && !_scheduledAmbient
            ? math.sin(progress * math.pi * 2) * .45
            : 0.0;
        return KeyedSubtree(
          key: ValueKey(
            'activityTicker-${_controller.isAnimating ? 'active' : 'stopped'}',
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, idleShift),
              child: Opacity(
                opacity: widget.isVisible ? 1 : 0,
                child: _ActivityGlyph(
                  key: ValueKey(
                    preview == null
                        ? 'activity-${mode.name}'
                        : 'activityPose-${preview.name}',
                  ),
                  size: widget.size,
                  asset: asset,
                  frame: frame,
                  fallbackColor: widget.colors.accent,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ActivityGlyph extends StatelessWidget {
  const _ActivityGlyph({
    super.key,
    required this.size,
    required this.asset,
    required this.frame,
    required this.fallbackColor,
  });

  final double size;
  final String asset;
  final int frame;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Image.asset(
      asset,
      key: ValueKey('activitySprite-$frame'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => Icon(
        Icons.directions_walk_rounded,
        size: size * .82,
        color: fallbackColor,
      ),
    ),
  );
}

List<String> _activityAssets(bool compact) => [
  for (final frame in [0, 8])
    for (var step = 0; step < 7; step++)
      'assets/character/${compact ? "dashboard_" : ""}transition_idle_run_${frame.toString().padLeft(2, "0")}_${step.toString().padLeft(2, "0")}.png',
  compact ? 'assets/character/dashboard_idle.png' : 'assets/character/idle.png',
  for (var index = 0; index < 16; index++)
    'assets/character/${compact ? 'dashboard_' : ''}walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 16; index++)
    'assets/character/${compact ? 'dashboard_' : ''}run_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 4; index++)
    'assets/character/${compact ? 'dashboard_' : ''}transition_idle_walk_${index.toString().padLeft(2, '0')}.png',
  for (var index = 0; index < 5; index++)
    'assets/character/${compact ? 'dashboard_' : ''}transition_walk_run_${index.toString().padLeft(2, '0')}.png',
];

Future<void> preloadBalanceActivitySprites() async {
  final assets = {..._activityAssets(false), ..._activityAssets(true)};
  await Future.wait(
    assets.map((asset) {
      final complete = Completer<void>();
      final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          stream.removeListener(listener);
          if (!complete.isCompleted) complete.complete();
        },
        onError: (Object error, StackTrace? stackTrace) {
          stream.removeListener(listener);
          if (!complete.isCompleted) complete.complete();
        },
      );
      stream.addListener(listener);
      return complete.future;
    }),
  );
}

String _activityAsset(
  BalanceActivityAnimationMode mode,
  int frame, {
  required bool compact,
}) {
  if (mode == BalanceActivityAnimationMode.idle) {
    return compact
        ? 'assets/character/dashboard_idle.png'
        : 'assets/character/idle.png';
  }
  final prefix = compact ? 'dashboard_' : '';
  final gait = mode == BalanceActivityAnimationMode.run ? 'run' : 'walk';
  return 'assets/character/$prefix${gait}_${frame.toString().padLeft(2, '0')}.png';
}

double _previewPhase(BalanceActivityPose pose) => switch (pose) {
  BalanceActivityPose.idle || BalanceActivityPose.walkContact => 0,
  BalanceActivityPose.walkDown => .125,
  BalanceActivityPose.walkPassing => .25,
  BalanceActivityPose.walkUp => .375,
  BalanceActivityPose.walkOppositeContact => .5,
  BalanceActivityPose.walkOppositeDown => .625,
  BalanceActivityPose.walkOppositePassing => .75,
  BalanceActivityPose.walkOppositeUp => .875,
  BalanceActivityPose.runContact => 0,
  BalanceActivityPose.runDown => .125,
  BalanceActivityPose.runFlight => .25,
  BalanceActivityPose.runRecovery => .375,
  BalanceActivityPose.runOppositeContact => .5,
  BalanceActivityPose.runOppositeDown => .625,
  BalanceActivityPose.runOppositeFlight => .75,
  BalanceActivityPose.runOppositeRecovery => .875,
};

double _previewRunBlend(BalanceActivityPose pose) => switch (pose) {
  BalanceActivityPose.runContact ||
  BalanceActivityPose.runDown ||
  BalanceActivityPose.runFlight ||
  BalanceActivityPose.runRecovery ||
  BalanceActivityPose.runOppositeContact ||
  BalanceActivityPose.runOppositeDown ||
  BalanceActivityPose.runOppositeFlight ||
  BalanceActivityPose.runOppositeRecovery => 1,
  _ => 0,
};
