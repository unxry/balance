import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double _waterChamberHeightFraction = .62;
const double _waterFullHeadspaceFactor = .96;

Future<ui.FragmentProgram>? _waterMaterialProgram;
ui.FragmentProgram? _loadedWaterMaterialProgram;

Future<void> preloadWaterMaterial() async {
  _loadedWaterMaterialProgram ??= await (_waterMaterialProgram ??=
      ui.FragmentProgram.fromAsset('shaders/water_material.frag'));
}

@visibleForTesting
double debugWaterChamberFill(double valueMl, double goalMl) {
  if (goalMl <= 0 || valueMl <= 0) return 0;
  return (valueMl / goalMl).clamp(0.0, 1.0) * _waterFullHeadspaceFactor;
}

double _surfaceTimeWave(double x, double elapsedSeconds, double offset) {
  final tau = math.pi * 2;
  final mainAngle = elapsedSeconds * .39;
  final secondaryAngle = elapsedSeconds * .263;
  final crestCenter = .53 + math.sin(secondaryAngle * .47 + tau * offset) * .11;
  final crestDistance = (x - crestCenter) / .29;
  final crestWindow = math.exp(-crestDistance * crestDistance);
  final counterCrestCenter =
      .25 + math.sin(secondaryAngle * .29 - tau * offset + 1.1) * .08;
  final counterCrestDistance = (x - counterCrestCenter) / .2;
  final counterCrestWindow = math.exp(
    -counterCrestDistance * counterCrestDistance,
  );
  return math.sin(tau * x * .72 + mainAngle + tau * offset) * .49 +
      math.sin(tau * x * 1.12 - secondaryAngle + tau * offset * .61 + .8) *
          .17 +
      math.sin(tau * x * 1.52 - mainAngle * .57 + tau * offset + .4) *
          .075 *
          crestWindow +
      math.sin(tau * x * 2.04 + secondaryAngle * .61 - tau * offset + 1.6) *
          .04 *
          counterCrestWindow;
}

@visibleForTesting
double debugWaterSurfaceSample(double x, double elapsedSeconds) =>
    _surfaceTimeWave(x, elapsedSeconds, 0);

List<double> _surfaceWaveSamples(
  int points,
  double elapsedSeconds,
  double offset,
) {
  final values = [
    for (var i = 0; i <= points; i++)
      _surfaceTimeWave(i / points, elapsedSeconds, offset),
  ];
  final mean = values.reduce((a, b) => a + b) / values.length;
  return [for (final value in values) value - mean];
}

@visibleForTesting
List<double> debugWaterSurfaceProfile(double elapsedSeconds) =>
    _surfaceWaveSamples(28, elapsedSeconds, 0);

@visibleForTesting
double debugAdvanceWaterMotionTime(double current, double realDelta) =>
    current + realDelta.clamp(0.0, .05);

({double x, double morph}) _causticMotion(int index, double elapsedSeconds) =>
    (x: .27 + index * .23, morph: math.sin(index * .87));

@visibleForTesting
({double x, double morph}) debugWaterCausticSample(
  int index,
  double elapsedSeconds,
) => _causticMotion(index, elapsedSeconds);

({double x, double morph}) _refractionMotion(
  int index,
  double elapsedSeconds,
) => (x: .25 + index * .25, morph: math.sin(index * .91));

@visibleForTesting
({double x, double morph}) debugWaterRefractionSample(
  int index,
  double elapsedSeconds,
) => _refractionMotion(index, elapsedSeconds);

@visibleForTesting
Map<String, List<double>> debugWaterRoiMotionSignals(double elapsedSeconds) {
  List<double> optics(double x, double depth, int index) {
    const lowerTime = 0.0;
    final caustic = _causticMotion(index, elapsedSeconds);
    final refraction = _refractionMotion(index, elapsedSeconds);
    return [
      lowerTime * .019,
      -lowerTime * .014,
      math.sin(depth * 5.2 + lowerTime * .13) * .136,
      math.sin(x * 4.4 - lowerTime * .11) * .136,
      caustic.x,
      caustic.morph * .35,
      refraction.x,
      refraction.morph * .25,
      math.sin(elapsedSeconds * .073 + index * 1.7 + 1.2) * .025,
    ];
  }

  return {
    'surface': debugWaterSurfaceProfile(elapsedSeconds),
    'center': optics(.5, .55, 1),
    'bottomLeft': [...optics(.08, .91, 0), .22 + .04 * math.sin(1.2)],
    'bottomRight': [...optics(.92, .9, 2), .79 + .036 * math.sin(5.1)],
    'bottomCenter': [...optics(.5, .82, 1), .6 + .04 * math.sin(3.4)],
  };
}

({double progress, double opacity, bool active}) _bubbleLifecycle({
  required double elapsedSeconds,
  required double spawnTime,
  required double lifetime,
  required double invisibleDelay,
}) {
  final cycleDuration = lifetime + invisibleDelay;
  final localTime = (elapsedSeconds + spawnTime) % cycleDuration;
  if (localTime >= lifetime) {
    return (progress: 1, opacity: 0, active: false);
  }
  final progress = localTime / lifetime;
  final fadeIn = (progress / .1).clamp(0.0, 1.0);
  final fadeOut = ((1 - progress) / .18).clamp(0.0, 1.0);
  return (progress: progress, opacity: math.min(fadeIn, fadeOut), active: true);
}

@visibleForTesting
({double progress, double opacity, bool active}) debugWaterBubbleLifecycle({
  required double elapsedSeconds,
  required double spawnTime,
  required double lifetime,
  required double invisibleDelay,
}) => _bubbleLifecycle(
  elapsedSeconds: elapsedSeconds,
  spawnTime: spawnTime,
  lifetime: lifetime,
  invisibleDelay: invisibleDelay,
);

/// The supplied water photograph is the canonical visual acceptance spec,
/// not a mood reference. Keep this rendering optically close to that image.
class RealisticWaterLayer extends StatefulWidget {
  const RealisticWaterLayer({
    super.key,
    required this.valueMl,
    required this.goalMl,
    required this.colors,
    this.previewElapsedSeconds,
    this.debugBubbleLabels = false,
    this.materialPreviewShader,
    @visibleForTesting this.forcePainterMaterial = false,
  });

  final double valueMl;
  final double goalMl;
  final AppColors colors;
  final double? previewElapsedSeconds;
  final bool debugBubbleLabels;
  final ui.FragmentShader? materialPreviewShader;
  final bool forcePainterMaterial;

  @override
  State<RealisticWaterLayer> createState() => _RealisticWaterLayerState();
}

class _RealisticWaterLayerState extends State<RealisticWaterLayer>
    with TickerProviderStateMixin {
  final Stopwatch _motionClock = Stopwatch()..start();
  int _lastMotionMicros = 0;
  double _visualMotionSeconds = 0;
  late final AnimationController _idle = AnimationController(
    vsync: this,
    // This controller only requests repaints. Visual time comes from the
    // monotonic stopwatch, so this pulse can wrap without resetting water.
    duration: const Duration(seconds: 1),
  );
  late final AnimationController _level = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  )..value = 1;
  late final AnimationController _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..value = 1;

  late double _fillFrom = _targetFill;
  late double _fillTo = _targetFill;
  double _reactionCarry = 0;
  double _sloshCarry = 0;
  double _sloshDirection = 1;
  double _bubbleBurstCarry = 0;
  bool _isIncrease = false;
  ui.FragmentShader? _materialShader;

  double get _targetFill {
    // The lower 62% of the card is the liquid chamber. Keep a small headspace
    // at full while preserving a physically proportional 0...2500 ml level.
    return debugWaterChamberFill(widget.valueMl, widget.goalMl);
  }

  double _motionSeconds() {
    final now = _motionClock.elapsedMicroseconds;
    if (_lastMotionMicros == 0) {
      _lastMotionMicros = now;
      return _visualMotionSeconds;
    }
    final elapsed = (now - _lastMotionMicros) / Duration.microsecondsPerSecond;
    _lastMotionMicros = now;
    _visualMotionSeconds = debugAdvanceWaterMotionTime(
      _visualMotionSeconds,
      elapsed,
    );
    return _visualMotionSeconds;
  }

  double get _currentFill {
    final t = _levelProgress(_level.value);
    return (_fillFrom + (_fillTo - _fillFrom) * t)
        .clamp(0.0, _waterFullHeadspaceFactor)
        .toDouble();
  }

  double _levelProgress(double t) {
    final overshoot = _isIncrease ? .010 : .008;
    if (t < .12) {
      return .03 * Curves.easeInOutSine.transform(t / .12);
    }
    if (t < .82) {
      final travel = Curves.easeInOutCubic.transform((t - .12) / .70);
      return .03 + (1 + overshoot - .03) * travel;
    }
    final settle = ((t - .82) / .18).clamp(0.0, 1.0);
    final smoothSettle = settle * settle * (3 - 2 * settle);
    return 1 + overshoot * (1 - smoothSettle) * math.cos(settle * math.pi * 2);
  }

  double _reactionEnvelope(double t) {
    final response = Curves.easeOutCubic.transform((t / .14).clamp(0.0, 1.0));
    return response * math.pow(1 - t, 2.2).toDouble();
  }

  double get _currentReaction {
    final t = _reaction.value;
    final carry = _reactionCarry * math.pow(1 - t, 2.4).toDouble();
    return (carry + _reactionEnvelope(t)).clamp(0.0, 1.12).toDouble();
  }

  double get _currentSlosh {
    final t = _reaction.value;
    final carry = _sloshCarry * math.pow(1 - t, 2.8).toDouble();
    final response =
        math.sin(math.pi * 5.2 * t) * math.pow(1 - t, 1.75).toDouble();
    return (carry + response * _sloshDirection).clamp(-1.05, 1.05).toDouble();
  }

  double get _currentBubbleBurst {
    final t = _reaction.value;
    final carry = _bubbleBurstCarry * math.pow(1 - t, 2.4).toDouble();
    final response = _isIncrease ? _reactionEnvelope(t) : 0.0;
    return (carry + response).clamp(0.0, 1.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _level.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _syncIdle();
    });
    if (!widget.forcePainterMaterial && widget.materialPreviewShader == null) {
      _materialShader = _loadedWaterMaterialProgram?.fragmentShader();
    }
    if (_materialShader == null &&
        !widget.forcePainterMaterial &&
        widget.materialPreviewShader == null) {
      unawaited(_loadMaterialShader());
    }
  }

  Future<void> _loadMaterialShader() async {
    try {
      await preloadWaterMaterial();
      final program = _loadedWaterMaterialProgram!;
      final shader = program.fragmentShader();
      if (!mounted) {
        shader.dispose();
        return;
      }
      setState(() => _materialShader = shader);
    } catch (_) {
      // Keep the deterministic painter fallback if the runtime effect is
      // unavailable on a platform.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIdle();
  }

  void _syncIdle() {
    if (widget.previewElapsedSeconds != null ||
        MediaQuery.disableAnimationsOf(context) ||
        (_fillTo <= .002 && _level.isCompleted)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RealisticWaterLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _targetFill;
    final amountChanged = widget.valueMl != oldWidget.valueMl;
    final visualFill = _currentFill;
    final carriedReaction = _currentReaction;
    final carriedSlosh = _currentSlosh;
    final carriedBubbleBurst = _currentBubbleBurst;
    _isIncrease = widget.valueMl > oldWidget.valueMl;
    _sloshDirection = _isIncrease ? -1 : 1;
    if ((next - _fillTo).abs() > .0001) {
      _fillFrom = visualFill;
      _fillTo = next;
      _level.duration = Duration(milliseconds: _isIncrease ? 1650 : 1800);
      _level.forward(from: 0);
    }
    if (amountChanged) {
      _reactionCarry = carriedReaction;
      _sloshCarry = carriedSlosh;
      _bubbleBurstCarry = carriedBubbleBurst;
      _reaction.duration = Duration(milliseconds: _isIncrease ? 3000 : 3200);
      _reaction.forward(from: 0);
    }
    _syncIdle();
  }

  @override
  void dispose() {
    _materialShader?.dispose();
    _idle.dispose();
    _level.dispose();
    _reaction.dispose();
    super.dispose();
  }

  @visibleForTesting
  Object get debugLevelControllerIdentity => _level;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _level, _reaction]),
        builder: (context, _) {
          final reactionT = _reaction.value;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          return CustomPaint(
            painter: _RealisticWaterPainter(
              colors: widget.colors,
              fill: _currentFill,
              elapsedSeconds: widget.previewElapsedSeconds == null
                  ? reduceMotion
                        ? 0
                        : _motionSeconds()
                  : widget.previewElapsedSeconds!,
              reaction: _currentReaction,
              slosh: _currentSlosh,
              reactionProgress: reactionT,
              bubbleBurst: _currentBubbleBurst,
              debugBubbleLabels: widget.debugBubbleLabels,
              materialShader: widget.forcePainterMaterial
                  ? null
                  : widget.materialPreviewShader ?? _materialShader,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class WaterProgressIndicators extends StatelessWidget {
  const WaterProgressIndicators({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    this.count = 8,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1700),
      curve: Curves.easeInOutCubic,
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      builder: (context, value, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: List.generate(count, (index) {
            final fill = (value * count - index).clamp(0.0, 1.0);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == count - 1 ? 0 : 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: ColoredBox(
                    color: trackColor,
                    child: SizedBox(
                      height: 6,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fill,
                        child: ColoredBox(color: activeColor),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _RealisticWaterPainter extends CustomPainter {
  const _RealisticWaterPainter({
    required this.colors,
    required this.fill,
    required this.elapsedSeconds,
    required this.reaction,
    required this.slosh,
    required this.reactionProgress,
    required this.bubbleBurst,
    required this.debugBubbleLabels,
    required this.materialShader,
  });

  final AppColors colors;
  final double fill;
  final double elapsedSeconds;
  final double reaction;
  final double slosh;
  final double reactionProgress;
  final double bubbleBurst;
  final bool debugBubbleLabels;
  final ui.FragmentShader? materialShader;

  bool get _dark => colors.brightness == Brightness.dark;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || fill <= .002) return;

    final chamberHeight = size.height * _waterChamberHeightFraction;
    final waterHeight = chamberHeight * fill;
    final surfaceY = size.height - waterHeight + slosh * 2.4;
    final nearEmptyScale = (.42 + math.sqrt(fill.clamp(0.0, .18) / .18) * .58)
        .clamp(.42, 1.0);
    final fullDamping = fill > .72 ? 1 - (fill - .72) / .24 * .1 : 1.0;
    final requestedAmplitude =
        (15.2 + reaction * 2.4 + slosh.abs() * .8) *
        nearEmptyScale *
        fullDamping.clamp(.9, 1.0);
    final amplitude = math.min(
      requestedAmplitude,
      math.max(.7, waterHeight * .4),
    );
    final front = _waterPath(size, surfaceY, amplitude, 0);
    final hybridMaterial = materialShader != null;
    if (hybridMaterial) {
      materialShader!
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, elapsedSeconds)
        ..setFloat(3, surfaceY / size.height)
        ..setFloat(4, _dark ? 1 : 0);
    }
    final bodyPaint = Paint();
    bodyPaint.shader =
        materialShader ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .24, .72, 1],
          colors: _dark
              ? const [
                  Color(0x309AA9AE),
                  Color(0x3A566E78),
                  Color(0x493C535E),
                  Color(0x55293E48),
                ]
              : const [
                  Color(0x20DCEAEC),
                  Color(0x4291B8C7),
                  Color(0x606E93A5),
                  Color(0x744C6C80),
                ],
        ).createShader(
          Rect.fromLTWH(0, surfaceY, size.width, size.height - surfaceY),
        );
    canvas.drawPath(front, bodyPaint);

    canvas.save();
    canvas.clipPath(front);
    if (!hybridMaterial) _paintDepth(canvas, size, surfaceY);
    _paintBoundaryReflections(canvas, size, surfaceY);
    _paintSurfaceVolume(canvas, size, surfaceY, amplitude);
    _paintRefractions(canvas, size, surfaceY);
    _paintCaustics(canvas, size, surfaceY);
    _paintBubbles(canvas, size, surfaceY);
    canvas.restore();

    _paintSurface(canvas, size, surfaceY, amplitude);
  }

  double _waveY(
    double x,
    double base,
    double amplitude,
    double normalizedWave,
  ) {
    final wallMeniscus = -2.2 * (math.exp(-x * 24) + math.exp(-(1 - x) * 24));
    return base + normalizedWave * amplitude + wallMeniscus;
  }

  List<double> _waveSamples(int points, double offset) {
    return _surfaceWaveSamples(points, elapsedSeconds, offset);
  }

  Path _surfacePath(Size size, double y, double amplitude, double offset) {
    const points = 28;
    final waves = _waveSamples(points, offset);
    final samples = <Offset>[
      for (var i = 0; i <= points; i++)
        Offset(
          size.width * i / points,
          _waveY(i / points, y, amplitude, waves[i]),
        ),
    ];
    final path = Path()..moveTo(samples.first.dx, samples.first.dy);
    for (var i = 0; i < samples.length - 1; i++) {
      final before = i == 0 ? samples[i] : samples[i - 1];
      final current = samples[i];
      final next = samples[i + 1];
      final after = i + 2 < samples.length ? samples[i + 2] : next;
      path.cubicTo(
        current.dx + (next.dx - before.dx) / 6,
        current.dy + (next.dy - before.dy) / 6,
        next.dx - (after.dx - current.dx) / 6,
        next.dy - (after.dy - current.dy) / 6,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  Path _waterPath(Size size, double y, double amplitude, double offset) {
    final path = _surfacePath(size, y, amplitude, offset);
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  Path _surfaceRibbonPath(
    Size size,
    double topY,
    double bottomY,
    double amplitude,
    double topOffset,
    double bottomOffset,
  ) {
    const points = 24;
    final topWaves = _waveSamples(points, topOffset);
    final bottomWaves = _waveSamples(points, bottomOffset);
    final thicknessVariations = [
      for (var i = 0; i <= points; i++)
        math.sin(math.pi * 2 * (i / points) * .76 + elapsedSeconds * .237) *
                .58 +
            math.sin(
                  math.pi * 2 * (i / points) * 1.16 - elapsedSeconds * .163,
                ) *
                .25,
    ];
    final thicknessMean =
        thicknessVariations.reduce((a, b) => a + b) /
        thicknessVariations.length;
    final path = Path();
    for (var i = 0; i <= points; i++) {
      final x = i / points;
      final point = Offset(
        size.width * x,
        _waveY(x, topY, amplitude, topWaves[i]),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    for (var i = points; i >= 0; i--) {
      final x = i / points;
      final thicknessVariation = thicknessVariations[i] - thicknessMean;
      path.lineTo(
        size.width * x,
        _waveY(x, bottomY, amplitude * .58, bottomWaves[i]) +
            thicknessVariation,
      );
    }
    return path..close();
  }

  void _paintSurfaceVolume(
    Canvas canvas,
    Size size,
    double surfaceY,
    double amplitude,
  ) {
    final primary = _surfaceRibbonPath(
      size,
      surfaceY,
      surfaceY + 5.2,
      amplitude,
      0,
      .035,
    );
    canvas.drawPath(
      primary,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: _dark ? .18 : .34),
            const Color(0xFFE6F1F2).withValues(alpha: _dark ? .12 : .22),
            const Color(0xFF83A5AF).withValues(alpha: _dark ? .1 : .15),
            const Color(0xFF315867).withValues(alpha: _dark ? .08 : .1),
            Colors.transparent,
          ],
          stops: const [0, .13, .4, .72, 1],
        ).createShader(Rect.fromLTWH(0, surfaceY, size.width, 7.2)),
    );
    final refracted = _surfacePath(
      size,
      surfaceY + 2.8,
      amplitude,
      .018,
    ).computeMetrics().first;
    final silverLayer = _surfacePath(
      size,
      surfaceY + 1.45,
      amplitude * .82,
      .012,
    ).computeMetrics().first;
    canvas.save();
    canvas.clipPath(primary);
    canvas.drawPath(
      refracted.extractPath(refracted.length * .09, refracted.length * .27),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.05
        ..color = const Color(0xFF315D6B).withValues(alpha: _dark ? .14 : .2),
    );
    canvas.drawPath(
      silverLayer.extractPath(
        silverLayer.length * .31,
        silverLayer.length * .44,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .68
        ..color = const Color(0xFFBBD4DC).withValues(alpha: _dark ? .34 : .58),
    );
    canvas.drawPath(
      refracted.extractPath(refracted.length * .51, refracted.length * .64),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .72
        ..color = Colors.white.withValues(alpha: _dark ? .54 : .88),
    );
    canvas.drawPath(
      refracted.extractPath(refracted.length * .75, refracted.length * .81),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .48
        ..color = const Color(0xFFF4FBFC).withValues(alpha: _dark ? .34 : .62),
    );
    canvas.restore();
  }

  void _paintDepth(Canvas canvas, Size size, double surfaceY) {
    final rect = Rect.fromLTWH(0, surfaceY, size.width, size.height - surfaceY);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.55, -.55),
          radius: 1.35,
          colors: [
            Colors.white.withValues(alpha: _dark ? .035 : .085),
            colors.accent.withValues(alpha: _dark ? .025 : .018),
            const Color(0xFF214F62).withValues(alpha: _dark ? .17 : .1),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: _dark ? .02 : .055),
            Colors.transparent,
            const Color(0xFF1C3C49).withValues(alpha: _dark ? .12 : .055),
          ],
          stops: const [0, .45, 1],
        ).createShader(rect),
    );
    final bottomGlow = Rect.fromCenter(
      center: Offset(size.width * .54, size.height + 5),
      width: size.width * 1.08,
      height: math.max(16, rect.height * .42),
    );
    canvas.drawOval(
      bottomGlow,
      Paint()
        ..color = Colors.white.withValues(alpha: _dark ? .028 : .065)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final lightVisibility = ((rect.height - 8) / 16).clamp(0.0, 1.0);
    if (lightVisibility > .01) {
      final lightDrift = .5 + math.sin(elapsedSeconds * .041 + .4) * .08;
      final warmLight = Rect.fromCenter(
        center: Offset(lightDrift * size.width, surfaceY + rect.height * .48),
        width: size.width * .52,
        height: math.max(14, rect.height * .28),
      );
      canvas.drawOval(
        warmLight,
        Paint()
          ..color = const Color(
            0xFFFFF1D8,
          ).withValues(alpha: (_dark ? .055 : .19) * lightVisibility)
          ..blendMode = BlendMode.screen
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.5),
      );
      final coolDrift = .5 + math.sin(elapsedSeconds * .033 + 2.1) * .07;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(coolDrift * size.width, surfaceY + rect.height * .72),
          width: size.width * .38,
          height: math.max(12, rect.height * .22),
        ),
        Paint()
          ..color = const Color(
            0xFF2C5665,
          ).withValues(alpha: (_dark ? .05 : .045) * lightVisibility)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  void _paintBoundaryReflections(Canvas canvas, Size size, double surfaceY) {
    final waterHeight = size.height - surfaceY;
    final edgeVisibility = ((waterHeight - 1) / 9).clamp(0.0, 1.0);
    if (edgeVisibility <= .01) return;
    final left = Path()
      ..moveTo(2.1, surfaceY + math.min(4, waterHeight * .3))
      ..cubicTo(
        5.8,
        surfaceY + waterHeight * .34,
        2.4,
        size.height - 15,
        10.5,
        size.height - 5.2,
      );
    final right = Path()
      ..moveTo(size.width - 2.2, surfaceY + math.min(5, waterHeight * .34))
      ..cubicTo(
        size.width - 6.4,
        surfaceY + waterHeight * .42,
        size.width - 2.8,
        size.height - 16,
        size.width - 11.5,
        size.height - 5.4,
      );
    for (final edge in [left, right]) {
      final edgeMetric = edge.computeMetrics().first;
      const fragments = [(.03, .25), (.42, .59), (.77, .94)];
      for (var i = 0; i < fragments.length; i++) {
        final fragment = fragments[i];
        final strength = const [.48, .76, .38][i];
        final highlight = edgeMetric.extractPath(
          edgeMetric.length * fragment.$1,
          edgeMetric.length * fragment.$2,
        );
        canvas.drawPath(
          highlight,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.4
            ..color = Colors.white.withValues(
              alpha: (_dark ? .08 : .2) * edgeVisibility * strength,
            )
            ..blendMode = BlendMode.screen
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
        );
        canvas.drawPath(
          highlight,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = .48
            ..color = const Color(0xFFEAF7F8).withValues(
              alpha: (_dark ? .25 : .56) * edgeVisibility * strength,
            ),
        );
      }
    }

    final bottomVisibility = ((waterHeight - 6) / 10).clamp(0.0, 1.0);
    if (bottomVisibility <= .01) return;
    final bottom = Path()
      ..moveTo(size.width * .06, size.height - 6.4)
      ..cubicTo(
        size.width * .22,
        size.height - 1.2,
        size.width * .38,
        size.height - 3.6,
        size.width * .51,
        size.height - 2.2,
      )
      ..cubicTo(
        size.width * .68,
        size.height - .8,
        size.width * .78,
        size.height - 3.8,
        size.width * .94,
        size.height - 6.1,
      );
    final metric = bottom.computeMetrics().first;
    const bottomSegments = [(.03, .19), (.43, .57), (.8, .96)];
    for (var i = 0; i < bottomSegments.length; i++) {
      final segment = bottomSegments[i];
      final strength = const [.62, .86, .48][i];
      final band = metric.extractPath(
        metric.length * segment.$1,
        metric.length * segment.$2,
      );
      canvas.drawPath(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0
          ..color = Colors.white.withValues(
            alpha: (_dark ? .08 : .22) * bottomVisibility * strength,
          )
          ..blendMode = BlendMode.screen
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.7),
      );
      canvas.drawPath(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = .62
          ..color = Colors.white.withValues(
            alpha: (_dark ? .3 : .68) * bottomVisibility * strength,
          ),
      );
    }
    for (final x in [size.width * .1, size.width * .9]) {
      final flare = Rect.fromCenter(
        center: Offset(x, size.height - 6.2),
        width: size.width * .22,
        height: 18,
      );
      canvas.drawOval(
        flare,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(
                alpha: (_dark ? .2 : .58) * bottomVisibility,
              ),
              const Color(
                0xFFD9EBEE,
              ).withValues(alpha: (_dark ? .09 : .24) * bottomVisibility),
              Colors.transparent,
            ],
            stops: const [0, .36, 1],
          ).createShader(flare)
          ..blendMode = BlendMode.screen,
      );
      final innerFlare = Rect.fromCenter(
        center: Offset(x + (x < size.width * .5 ? 8 : -8), size.height - 10.5),
        width: size.width * .1,
        height: 10,
      );
      canvas.drawOval(
        innerFlare,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(
                alpha: (_dark ? .11 : .34) * bottomVisibility,
              ),
              Colors.transparent,
            ],
          ).createShader(innerFlare)
          ..blendMode = BlendMode.screen,
      );
    }
    for (final isLeft in [true, false]) {
      final corner = Path()
        ..moveTo(isLeft ? 3.2 : size.width - 3.2, size.height - 35)
        ..cubicTo(
          isLeft ? 3.8 : size.width - 3.8,
          size.height - 15,
          isLeft ? 13 : size.width - 13,
          size.height - 5.2,
          isLeft ? 39 : size.width - 39,
          size.height - 3.6,
        );
      final cornerMetric = corner.computeMetrics().first;
      const fragments = [(.06, .28), (.44, .64), (.79, .93)];
      for (var i = 0; i < fragments.length; i++) {
        final fragment = fragments[i];
        final strength = const [.56, .82, .4][i];
        final highlight = cornerMetric.extractPath(
          cornerMetric.length * fragment.$1,
          cornerMetric.length * fragment.$2,
        );
        canvas.drawPath(
          highlight,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.2
            ..color = Colors.white.withValues(
              alpha: (_dark ? .1 : .26) * bottomVisibility * strength,
            )
            ..blendMode = BlendMode.screen
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
        );
        canvas.drawPath(
          highlight,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = .48
            ..color = const Color(0xFFF4FBFC).withValues(
              alpha: (_dark ? .34 : .7) * bottomVisibility * strength,
            ),
        );
      }
    }
  }

  void _paintSurface(Canvas canvas, Size size, double y, double amplitude) {
    final surface = _surfacePath(size, y, amplitude, 0);
    canvas.drawPath(
      surface,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .46
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF7898A1).withValues(alpha: _dark ? .18 : .22),
            const Color(0xFFEAF5F6).withValues(alpha: _dark ? .3 : .38),
            const Color(0xFFD6E8EB).withValues(alpha: _dark ? .22 : .3),
            const Color(0xFF7898A1).withValues(alpha: _dark ? .14 : .18),
          ],
          stops: const [0, .3, .7, 1],
        ).createShader(Rect.fromLTWH(0, y - 2, size.width, 5)),
    );

    final metric = surface.computeMetrics().first;
    final highlightCenter = .5 + math.sin(elapsedSeconds * .109 + .3) * .2;
    final highlightHalfWidth = .035;
    final highlightRect = Rect.fromLTWH(
      size.width * (highlightCenter - highlightHalfWidth),
      y - 3,
      size.width * highlightHalfWidth * 2,
      6,
    );
    canvas.drawPath(
      metric.extractPath(
        metric.length * (highlightCenter - highlightHalfWidth),
        metric.length * (highlightCenter + highlightHalfWidth),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .5
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: _dark ? .48 : .78),
            Colors.white.withValues(alpha: _dark ? .36 : .62),
            Colors.transparent,
          ],
          stops: const [0, .38, .62, 1],
        ).createShader(highlightRect),
    );

    final secondaryCenter = .5 + math.sin(elapsedSeconds * .073 + 2.1) * .3;
    final secondaryHalfWidth = .016;
    final secondaryRect = Rect.fromLTWH(
      size.width * (secondaryCenter - secondaryHalfWidth),
      y - 3,
      size.width * secondaryHalfWidth * 2,
      6,
    );
    canvas.drawPath(
      metric.extractPath(
        metric.length * (secondaryCenter - secondaryHalfWidth),
        metric.length * (secondaryCenter + secondaryHalfWidth),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = .38
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFFFF8EA).withValues(alpha: _dark ? .24 : .5),
            Colors.transparent,
          ],
        ).createShader(secondaryRect),
    );
  }

  void _paintCaustics(Canvas canvas, Size size, double surfaceY) {
    final waterHeight = size.height - surfaceY;
    if (waterHeight < 3) return;
    for (var i = 0; i < 3; i++) {
      final causticVisibility = ((waterHeight - (5 + i * 3)) / 17).clamp(
        0.0,
        1.0,
      );
      if (causticVisibility <= .01) continue;
      final motion = _causticMotion(i, elapsedSeconds);
      final center = Offset(
        motion.x * size.width,
        surfaceY + waterHeight * (.24 + i * .2) + motion.morph * .35,
      );
      final width = 32.0 + i * 7;
      final height = 14.0 + (i % 2) * 5;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(motion.morph * .08);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-.18, -.1),
                colors: [
                  (i == 1 ? const Color(0xFFFFF1D8) : Colors.white).withValues(
                    alpha: (_dark ? .1 : .19) * causticVisibility,
                  ),
                  const Color(
                    0xFFB8D2DB,
                  ).withValues(alpha: (_dark ? .05 : .09) * causticVisibility),
                  Colors.transparent,
                ],
                stops: const [0, .52, 1],
              ).createShader(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: width,
                  height: height,
                ),
              )
          ..blendMode = BlendMode.screen
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.2),
      );
      canvas.restore();
    }
  }

  void _paintRefractions(Canvas canvas, Size size, double surfaceY) {
    final waterHeight = size.height - surfaceY;
    if (waterHeight < 2) return;
    for (var i = 0; i < 3; i++) {
      final visibility = ((waterHeight - 5) / 13).clamp(0.0, 1.0);
      if (visibility <= .01) continue;
      final motion = _refractionMotion(i, elapsedSeconds);
      final center = Offset(
        motion.x * size.width,
        surfaceY + waterHeight * (.24 + i * .2) + motion.morph * .25,
      );
      final width = 11.0 + i * 3.5;
      final height = 3.2 + (i % 2) * .8;
      final patch = Path()
        ..moveTo(-width * .5, height * .12)
        ..cubicTo(
          -width * .2,
          -height * .86,
          width * .18,
          -height * .48,
          width * .5,
          -height * .08,
        )
        ..cubicTo(
          width * .24,
          height * .58,
          -width * .12,
          height * .52,
          -width * .5,
          height * .12,
        )
        ..close();
      final opacity =
          (.205 + math.sin(elapsedSeconds * .073 + i * 1.7 + 1.2) * .025) *
          visibility;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.sin(i + .7) * .096);
      canvas.drawPath(
        patch,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-.12, -.12),
                radius: 1,
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  const Color(0xFFC5DDE3).withValues(alpha: opacity * .65),
                  Colors.transparent,
                ],
                stops: const [0, .48, 1],
              ).createShader(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: width,
                  height: height * 2,
                ),
              )
          ..blendMode = BlendMode.screen
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.1),
      );
      canvas.restore();
    }
  }

  void _paintBubbles(Canvas canvas, Size size, double surfaceY) {
    final waterHeight = size.height - surfaceY;
    final heightVisibility = ((waterHeight - 1) / 7).clamp(0.0, 1.0);
    if (heightVisibility <= .01) return;
    const specs =
        <
          ({
            double spawnTime,
            double lifetime,
            double invisibleDelay,
            double startX,
            double startY,
            double radius,
            double riseSpeed,
            double horizontalDrift,
            double wobbleAmplitude,
            double wobbleFrequency,
            int depth,
            double opacity,
            double highlightAngle,
          })
        >[
          (
            spawnTime: .4,
            lifetime: 6.8,
            invisibleDelay: 1.1,
            startX: .16,
            startY: .35,
            radius: .8,
            riseSpeed: .94,
            horizontalDrift: 3.2,
            wobbleAmplitude: 1.6,
            wobbleFrequency: 1.25,
            depth: 0,
            opacity: .46,
            highlightAngle: 3.9,
          ),
          (
            spawnTime: .75,
            lifetime: 7,
            invisibleDelay: 1.35,
            startX: .28,
            startY: .25,
            radius: 1.4,
            riseSpeed: 1.02,
            horizontalDrift: -4.1,
            wobbleAmplitude: 2.3,
            wobbleFrequency: 1.7,
            depth: 1,
            opacity: .7,
            highlightAngle: 4.15,
          ),
          (
            spawnTime: 1.1,
            lifetime: 7.2,
            invisibleDelay: .9,
            startX: .39,
            startY: .3,
            radius: .9,
            riseSpeed: .88,
            horizontalDrift: 2.5,
            wobbleAmplitude: 1.7,
            wobbleFrequency: 1.45,
            depth: 0,
            opacity: .48,
            highlightAngle: 3.55,
          ),
          (
            spawnTime: 1.6,
            lifetime: 5.4,
            invisibleDelay: 1.2,
            startX: .52,
            startY: .24,
            radius: 4.2,
            riseSpeed: .96,
            horizontalDrift: -5.2,
            wobbleAmplitude: 3.0,
            wobbleFrequency: 1.2,
            depth: 2,
            opacity: .9,
            highlightAngle: 4.0,
          ),
          (
            spawnTime: 5.1,
            lifetime: 7.2,
            invisibleDelay: 1.45,
            startX: .66,
            startY: .2,
            radius: 1.35,
            riseSpeed: .9,
            horizontalDrift: 4.4,
            wobbleAmplitude: 2.1,
            wobbleFrequency: 1.55,
            depth: 1,
            opacity: .66,
            highlightAngle: 3.7,
          ),
          (
            spawnTime: 1.8,
            lifetime: 4.6,
            invisibleDelay: 1.05,
            startX: .79,
            startY: .18,
            radius: 2,
            riseSpeed: 1.04,
            horizontalDrift: -3.3,
            wobbleAmplitude: 2.7,
            wobbleFrequency: 1.8,
            depth: 2,
            opacity: .84,
            highlightAngle: 4.25,
          ),
          (
            spawnTime: 2.15,
            lifetime: 6.25,
            invisibleDelay: 1.3,
            startX: .88,
            startY: .28,
            radius: .65,
            riseSpeed: .9,
            horizontalDrift: 2.8,
            wobbleAmplitude: 1.35,
            wobbleFrequency: 1.42,
            depth: 0,
            opacity: .44,
            highlightAngle: 3.8,
          ),
          (
            spawnTime: 4.15,
            lifetime: 5.85,
            invisibleDelay: 1.15,
            startX: .57,
            startY: .28,
            radius: 1.8,
            riseSpeed: .98,
            horizontalDrift: -3.7,
            wobbleAmplitude: 2.25,
            wobbleFrequency: 1.63,
            depth: 1,
            opacity: .71,
            highlightAngle: 4.08,
          ),
          (
            spawnTime: 2.85,
            lifetime: 6.4,
            invisibleDelay: 1.2,
            startX: .71,
            startY: .22,
            radius: .6,
            riseSpeed: .92,
            horizontalDrift: 2.4,
            wobbleAmplitude: 1.2,
            wobbleFrequency: 1.37,
            depth: 0,
            opacity: .42,
            highlightAngle: 3.64,
          ),
          (
            spawnTime: 2.65,
            lifetime: 5.1,
            invisibleDelay: 1.4,
            startX: .34,
            startY: .25,
            radius: 2.8,
            riseSpeed: 1.01,
            horizontalDrift: -4.5,
            wobbleAmplitude: 2.6,
            wobbleFrequency: 1.51,
            depth: 2,
            opacity: .82,
            highlightAngle: 4.2,
          ),
          (
            spawnTime: 1.95,
            lifetime: 5.7,
            invisibleDelay: .8,
            startX: .83,
            startY: .31,
            radius: 1.55,
            riseSpeed: .97,
            horizontalDrift: -3.1,
            wobbleAmplitude: 2.0,
            wobbleFrequency: 1.46,
            depth: 1,
            opacity: .75,
            highlightAngle: 3.92,
          ),
          (
            spawnTime: 4.65,
            lifetime: 6.9,
            invisibleDelay: .9,
            startX: .23,
            startY: .32,
            radius: .75,
            riseSpeed: .91,
            horizontalDrift: 2.1,
            wobbleAmplitude: 1.45,
            wobbleFrequency: 1.58,
            depth: 0,
            opacity: .55,
            highlightAngle: 3.72,
          ),
          (
            spawnTime: 1.7,
            lifetime: 8,
            invisibleDelay: 1.1,
            startX: .69,
            startY: .26,
            radius: 5.2,
            riseSpeed: .92,
            horizontalDrift: -4.3,
            wobbleAmplitude: 2.4,
            wobbleFrequency: 1.31,
            depth: 2,
            opacity: .86,
            highlightAngle: 4.05,
          ),
          (
            spawnTime: 3.6,
            lifetime: 8.2,
            invisibleDelay: 1.25,
            startX: .44,
            startY: .33,
            radius: 3.6,
            riseSpeed: .98,
            horizontalDrift: 3.8,
            wobbleAmplitude: 2,
            wobbleFrequency: 1.67,
            depth: 1,
            opacity: .8,
            highlightAngle: 3.82,
          ),
        ];
    const activationFills = [
      .018,
      .035,
      .11,
      .2,
      .42,
      .58,
      .66,
      .7,
      .76,
      .82,
      .72,
      .78,
      .88,
      .9,
    ];
    for (var index = 0; index < specs.length; index++) {
      final spec = specs[index];
      final volumeVisibility =
          ((fill - activationFills[index]) / .055).clamp(0.0, 1.0) *
          heightVisibility;
      if (volumeVisibility <= .01) continue;
      final lifecycle = _bubbleLifecycle(
        elapsedSeconds: elapsedSeconds,
        spawnTime: spec.spawnTime,
        lifetime: spec.lifetime,
        invisibleDelay: spec.invisibleDelay,
      );
      if (!lifecycle.active) continue;
      final life = lifecycle.progress;
      final easedRise = Curves.easeInOutSine.transform(life);
      final pause =
          math.sin(
            life * math.pi * 2 * (.68 + index * .07) + spec.highlightAngle,
          ) *
          .012 *
          (1 - life);
      final rise = (math.pow(easedRise, 1 / spec.riseSpeed) + pause)
          .clamp(0.0, 1.0)
          .toDouble();
      final fadeOut = ((1 - life) / .18).clamp(0.0, 1.0);
      final visibility = lifecycle.opacity * volumeVisibility;
      final xDrift =
          spec.horizontalDrift * life +
          math.sin(
                life * math.pi * 2 * spec.wobbleFrequency + spec.highlightAngle,
              ) *
              spec.wobbleAmplitude +
          math.sin(elapsedSeconds * .437 + spec.startX * math.pi * 2) * .7;
      final startY = size.height - waterHeight * spec.startY;
      final endY = surfaceY + spec.radius + 1.5;
      final verticalScatter = (((index * 7) % 5) - 2) * 3.1;
      final rawCenter = Offset(
        size.width * spec.startX + xDrift,
        startY + (endY - startY) * rise + verticalScatter,
      );
      final bottomLimit = size.height - spec.radius - 1;
      final center = Offset(
        rawCenter.dx,
        rawCenter.dy.clamp(math.min(endY, bottomLimit), bottomLimit),
      );
      final blur = switch (spec.depth) {
        0 => .55,
        1 => .12,
        _ => 0.0,
      };
      _bubble(
        canvas,
        center,
        spec.radius * (.96 + fadeOut * .04),
        visibility * math.min(1, spec.opacity * 1.9),
        blur: blur,
        highlightAngle: spec.highlightAngle,
        aspectRatio: 1 + math.sin(elapsedSeconds * .23 + index * 1.9) * .085,
      );
      if (debugBubbleLabels && index < 3 && visibility > .08) {
        _paintBubbleLabel(canvas, center, String.fromCharCode(65 + index));
      }
    }

    final microVisibility = ((fill - .12) / .32).clamp(0.0, 1.0);
    if (microVisibility > .01) {
      const micros = [
        (.16, .17, .34, .42),
        (.18, .24, 1.1, .36),
        (.2, .22, 1.7, .56),
        (.22, .3, 2.35, .34),
        (.25, .15, 3.1, .4),
        (.28, .2, 4.05, .46),
        (.31, .28, 4.8, .52),
        (.45, .19, 5.65, .34),
        (.52, .27, 1.35, .43),
        (.64, .27, 4.55, .35),
        (.67, .2, 2.4, .42),
        (.7, .3, 3.15, .33),
        (.72, .15, 5.2, .55),
        (.75, .21, 5.85, .38),
        (.77, .26, .8, .4),
        (.8, .14, 2.95, .32),
        (.82, .19, 3.8, .5),
        (.86, .31, 6.1, .38),
        (.14, .26, 2.02, .28),
        (.24, .25, 5.42, .31),
        (.29, .12, .92, .26),
        (.61, .18, 1.92, .27),
        (.69, .24, 4.18, .3),
        (.74, .32, 6.72, .25),
        (.84, .24, 2.68, .29),
      ];
      for (final micro in micros) {
        final center = Offset(
          size.width * micro.$1 +
              math.sin(elapsedSeconds * .17 + micro.$3) * .8,
          size.height -
              waterHeight * micro.$2 +
              math.sin(elapsedSeconds * .13 + micro.$3) * 1.2,
        );
        if (center.dy <= surfaceY + 1.2) continue;
        final depthOpacity = .62 + (micro.$3 * .37 % 1) * .34;
        final opacity =
            (.26 + .16 * (1 + math.sin(elapsedSeconds * .11 + micro.$3)) / 2) *
            microVisibility *
            depthOpacity;
        canvas.drawCircle(
          center,
          micro.$4,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
        canvas.drawCircle(
          center + Offset(micro.$4 * .5, micro.$4 * .42),
          micro.$4 * .34,
          Paint()
            ..color = const Color(0xFF527582).withValues(alpha: opacity * .55),
        );
      }
    }

    if (bubbleBurst <= .015) return;
    for (var i = 0; i < 3; i++) {
      final lift = ((reactionProgress - i * .08) / .78).clamp(0.0, 1.0);
      final center = Offset(
        size.width * (.34 + i * .18) + math.sin(elapsedSeconds * .73 + i) * 3,
        size.height - 8 - lift * waterHeight * (.42 + i * .12),
      );
      _bubble(
        canvas,
        center,
        1.5 + i * .8,
        (math.sin(math.pi * lift) * .8 * bubbleBurst).clamp(0.0, .8),
        blur: i == 0 ? .35 : 0,
        highlightAngle: 3.7 + i * .25,
        aspectRatio: 1 + math.sin(elapsedSeconds * .23 + i * 1.9) * .085,
      );
    }
  }

  void _paintBubbleLabel(Canvas canvas, Offset center, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFB54A32),
          fontFamily: 'Inter',
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center + const Offset(4, -10));
  }

  void _bubble(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity, {
    required double blur,
    required double highlightAngle,
    required double aspectRatio,
  }) {
    if (opacity <= .02) return;
    final lens = Rect.fromCenter(
      center: center,
      width: radius * 2.04 * aspectRatio,
      height: radius * 1.92 / aspectRatio,
    );
    final innerLens = Rect.fromCenter(
      center: center + Offset(radius * .06 * aspectRatio, radius * .08),
      width: radius * 1.42 * aspectRatio,
      height: radius * 1.28 / aspectRatio,
    );
    canvas.drawOval(
      innerLens,
      Paint()
        ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null
        ..shader = RadialGradient(
          center: const Alignment(.18, .24),
          colors: [
            Colors.transparent,
            Colors.transparent,
            const Color(0xFF315563).withValues(alpha: opacity * .18),
          ],
          stops: const [0, .58, 1],
        ).createShader(innerLens),
    );
    final rim = lens.deflate(math.max(.08, radius * .09));
    canvas.drawArc(
      rim,
      highlightAngle - .62,
      1.02,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.36, radius * .2)
        ..maskFilter = blur > 0
            ? MaskFilter.blur(BlurStyle.normal, blur * .5)
            : null
        ..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawArc(
      rim,
      highlightAngle + 2.32,
      .48,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.18, radius * .09)
        ..color = const Color(0xFF244A58).withValues(alpha: opacity * .2),
    );
    canvas.drawArc(
      rim,
      highlightAngle + 1.18,
      .3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.2, radius * .08)
        ..color = const Color(0xFFDCECEF).withValues(alpha: opacity * .38),
    );
    canvas.drawCircle(
      center +
          Offset(
            math.cos(highlightAngle) * radius * .42 * aspectRatio,
            math.sin(highlightAngle) * radius * .42 / aspectRatio,
          ),
      math.max(.18, radius * .12),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticWaterPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.reaction != reaction ||
      oldDelegate.slosh != slosh ||
      oldDelegate.reactionProgress != reactionProgress ||
      oldDelegate.bubbleBurst != bubbleBurst ||
      oldDelegate.debugBubbleLabels != debugBubbleLabels ||
      oldDelegate.materialShader != materialShader ||
      oldDelegate.colors != colors;
}
