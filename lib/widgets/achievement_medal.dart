import 'dart:async';

import 'package:flutter/material.dart';

import '../models/achievement_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/balance_motion.dart';
import 'common.dart';

class AchievementMedal extends StatefulWidget {
  final AchievementProgress achievement;
  final AppColors colors;
  final double size;
  final bool animateHighlight;

  const AchievementMedal({
    super.key,
    required this.achievement,
    required this.colors,
    this.size = 62,
    this.animateHighlight = true,
  });

  @override
  State<AchievementMedal> createState() => _AchievementMedalState();
}

class _AchievementMedalState extends State<AchievementMedal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  Timer? _idleTimer;
  bool _motionEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AchievementMedal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final enabled =
        widget.animateHighlight &&
        widget.achievement.state == AchievementState.unlocked &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _motionEnabled = enabled;
    if (enabled && !_controller.isAnimating) {
      _playMotion();
    } else if (!enabled) {
      _idleTimer?.cancel();
      _idleTimer = null;
      _controller.stop();
      _controller.value = 0;
    }
  }

  void _playMotion() {
    if (_controller.isAnimating || _idleTimer != null) return;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _idleTimer = Timer(const Duration(milliseconds: 6500), () {
        _idleTimer = null;
        _syncMotion();
      });
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.achievement.state == AchievementState.unlocked;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final shimmer = _motionWindow(_controller.value, .05, .27);
          final glow = _softPulse(_motionWindow(_controller.value, 0, .32));
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (unlocked)
                Transform.scale(
                  scale: .92 + glow * .07,
                  child: Container(
                    key: const ValueKey('achievementMedalGlow'),
                    width: widget.size * 1.06,
                    height: widget.size * 1.06,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.colors.champagne.withValues(
                            alpha: .16 + glow * .10,
                          ),
                          widget.colors.accent.withValues(alpha: .045),
                          Colors.transparent,
                        ],
                        stops: const [0, .58, 1],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.colors.champagne.withValues(
                            alpha: .10 + glow * .06,
                          ),
                          blurRadius: widget.size * .22,
                          spreadRadius: -widget.size * .07,
                        ),
                      ],
                    ),
                  ),
                ),
              CustomPaint(
                size: Size.square(widget.size),
                painter: _MedalPainter(
                  colors: widget.colors,
                  tier: widget.achievement.definition.tier,
                  unlocked: unlocked,
                  highlight: shimmer,
                ),
              ),
              Icon(
                _symbol(widget.achievement.definition.symbol),
                size: widget.size * .34,
                color: unlocked
                    ? widget.colors.fg.withValues(alpha: .82)
                    : widget.colors.muted.withValues(alpha: .65),
              ),
              if (unlocked && _motionEnabled)
                _AchievementSparkles(
                  progress: _controller.value,
                  color: widget.colors.champagne,
                  size: widget.size,
                ),
              if (!unlocked)
                Positioned(
                  right: widget.size * .08,
                  bottom: widget.size * .08,
                  child: Container(
                    width: widget.size * .25,
                    height: widget.size * .25,
                    decoration: BoxDecoration(
                      color: widget.colors.card2,
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.colors.line2),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: widget.size * .13,
                      color: widget.colors.muted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

double _motionWindow(double value, double start, double end) =>
    ((value - start) / (end - start)).clamp(0.0, 1.0);

double _softPulse(double value) =>
    value <= 0 || value >= 1 ? 0 : (value < .5 ? value * 2 : (1 - value) * 2);

class _AchievementSparkles extends StatelessWidget {
  const _AchievementSparkles({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = _motionWindow(progress, .08, .25);
    final b = _motionWindow(progress, .18, .36);
    final c = _motionWindow(progress, .62, .76);
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          key: const ValueKey('achievementSparkles'),
          clipBehavior: Clip.none,
          children: [
            _sparkle(
              left: size * .05,
              top: size * (.16 - a * .08),
              opacity: _softPulse(a),
              scale: .72 + a * .28,
              glyph: '✦',
            ),
            _sparkle(
              right: size * .02,
              top: size * .35,
              opacity: _softPulse(b),
              scale: .64 + b * .36,
              glyph: '·',
            ),
            _sparkle(
              right: size * .13,
              bottom: size * (.08 + c * .05),
              opacity: _softPulse(c) * .72,
              scale: .7 + c * .24,
              glyph: '✦',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sparkle({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double opacity,
    required double scale,
    required String glyph,
  }) => Positioned(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    child: Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Text(
          glyph,
          style: TextStyle(
            color: color,
            fontSize: glyph == '·' ? size * .22 : size * .13,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

class _MedalPainter extends CustomPainter {
  final AppColors colors;
  final AchievementTier tier;
  final bool unlocked;
  final double highlight;

  const _MedalPainter({
    required this.colors,
    required this.tier,
    required this.unlocked,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final metal = switch (tier) {
      AchievementTier.bronze => colors.bronze,
      AchievementTier.silver => colors.silver,
      AchievementTier.gold => colors.champagne,
      AchievementTier.premium => colors.accent,
    };
    final mutedMetal = Color.lerp(metal, colors.card2, unlocked ? .1 : .72)!;
    canvas.drawCircle(
      center,
      outer - 1,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.42),
          radius: 1.05,
          colors: [
            Color.lerp(mutedMetal, Colors.white, unlocked ? .34 : .12)!,
            mutedMetal,
            Color.lerp(mutedMetal, colors.fg, .26)!,
          ],
          stops: const [0, .58, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      outer - 4,
      Paint()
        ..color = unlocked
            ? colors.champagne.withValues(alpha: .92)
            : colors.line2.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      outer * .68,
      Paint()
        ..color = colors.fg.withValues(alpha: unlocked ? .12 : .06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (unlocked && highlight > 0 && highlight < 1) {
      final x = -size.width + size.width * 3 * highlight;
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: outer - 2)),
      );
      canvas.rotate(-.28);
      canvas.drawRect(
        Rect.fromLTWH(x, -size.height, size.width * .18, size.height * 3),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .48),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MedalPainter oldDelegate) =>
      oldDelegate.highlight != highlight ||
      oldDelegate.unlocked != unlocked ||
      oldDelegate.tier != tier ||
      oldDelegate.colors != colors;
}

IconData _symbol(String symbol) => switch (symbol) {
  'scale' => Icons.monitor_weight_outlined,
  'path' => Icons.trending_up_rounded,
  'mountain' => Icons.landscape_outlined,
  'flag' => Icons.flag_outlined,
  'leaf' => Icons.eco_outlined,
  'book' => Icons.menu_book_outlined,
  'balance' => Icons.balance_outlined,
  'seed' => Icons.grass_outlined,
  'drop' => Icons.water_drop_outlined,
  'waves' => Icons.waves_rounded,
  'walk' => Icons.directions_walk_rounded,
  'trail' => Icons.route_outlined,
  'flame' => Icons.local_fire_department_outlined,
  'sun' => Icons.wb_sunny_outlined,
  'archive' => Icons.inventory_2_outlined,
  'chef' => Icons.restaurant_menu_rounded,
  'calendar' => Icons.calendar_month_outlined,
  'diamond' => Icons.diamond_outlined,
  _ => Icons.auto_awesome_outlined,
};

Future<void> showAchievementDetails(
  BuildContext context,
  AchievementProgress achievement, {
  required bool isRu,
}) async {
  final colors = context.colors;
  final text = AppText(colors);
  final definition = achievement.definition;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.line2,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 22),
            AchievementMedal(
              achievement: achievement,
              colors: colors,
              size: 112,
            ),
            const SizedBox(height: 18),
            Text(
              isRu ? definition.titleRu : definition.titleEn,
              textAlign: TextAlign.center,
              style: text.fraunces(size: 25, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Pill(
              text: _tierLabel(definition.tier, isRu),
              bg: colors.champagne.withValues(alpha: .16),
              fg: colors.fg2,
              mono: true,
            ),
            const SizedBox(height: 8),
            Text(
              isRu ? definition.descriptionRu : definition.descriptionEn,
              textAlign: TextAlign.center,
              style: text.inter(size: 13, color: colors.fg2, height: 1.45),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: achievement.fraction,
                backgroundColor: colors.track,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  isRu ? 'Прогресс' : 'Progress',
                  style: text.mono(size: 9, color: colors.muted),
                ),
                const Spacer(),
                Text(
                  '${_number(achievement.currentValue)} / ${_number(definition.targetValue)}',
                  style: text.mono(size: 9, color: colors.fg),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.card2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.state == AchievementState.unlocked
                        ? (isRu ? 'ПОЛУЧЕНО' : 'UNLOCKED')
                        : (isRu ? 'КАК ПОЛУЧИТЬ' : 'HOW TO UNLOCK'),
                    style: text.mono(size: 9, color: colors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    achievement.state == AchievementState.unlocked
                        ? (achievement.unlockedAt == null
                              ? (isRu ? 'Получено' : 'Unlocked')
                              : _date(achievement.unlockedAt!, isRu))
                        : (isRu
                              ? definition.requirementRu
                              : definition.requirementEn),
                    style: text.inter(
                      size: 12,
                      weight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (achievement.state != AchievementState.unlocked) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${isRu ? 'Осталось' : 'Remaining'}: ${_number(achievement.remaining)}',
                      style: text.mono(size: 9, color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _tierLabel(AchievementTier tier, bool isRu) => switch (tier) {
  AchievementTier.bronze => isRu ? 'БРОНЗА' : 'BRONZE',
  AchievementTier.silver => isRu ? 'СЕРЕБРО' : 'SILVER',
  AchievementTier.gold => isRu ? 'ЗОЛОТО' : 'GOLD',
  AchievementTier.premium => 'PREMIUM',
};

Future<void> showAchievementReveal(
  BuildContext context,
  AchievementProgress achievement, {
  required bool isRu,
}) async {
  if (!MediaQuery.disableAnimationsOf(context)) {
    unawaited(BalanceMotion.achievement());
  }
  final colors = context.colors;
  final text = AppText(colors);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: isRu ? 'Новое достижение' : 'New achievement',
    barrierColor: colors.fg.withValues(alpha: .42),
    transitionDuration: BalanceMotion.screen,
    pageBuilder: (dialogContext, __, ___) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 292,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.champagne.withValues(alpha: .55)),
            boxShadow: [
              BoxShadow(
                color: colors.champagne.withValues(alpha: .2),
                blurRadius: 42,
                spreadRadius: 3,
              ),
            ],
          ),
          child: TweenAnimationBuilder<double>(
            key: const ValueKey('achievementUnlockSequence'),
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(dialogContext)
                ? Duration.zero
                : const Duration(milliseconds: 850),
            curve: Curves.linear,
            builder: (_, value, __) {
              final labelStage = _motionWindow(value, 0, .2);
              final medalStage = Curves.easeOutCubic.transform(
                _motionWindow(value, .08, .48),
              );
              final titleStage = Curves.easeOutCubic.transform(
                _motionWindow(value, .44, .76),
              );
              final descriptionStage = Curves.easeOutCubic.transform(
                _motionWindow(value, .62, .84),
              );
              final completionStage = Curves.easeOutCubic.transform(
                _motionWindow(value, .78, 1),
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: labelStage,
                    child: Text(
                      isRu ? 'НОВОЕ ДОСТИЖЕНИЕ' : 'NEW ACHIEVEMENT',
                      style: text.mono(size: 9, color: colors.muted),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: medalStage,
                    child: Transform.scale(
                      scale: .96 + .04 * medalStage,
                      child: AchievementMedal(
                        achievement: achievement,
                        colors: colors,
                        size: 126,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: titleStage,
                    child: Transform.translate(
                      offset: Offset(0, 7 * (1 - titleStage)),
                      child: Text(
                        isRu
                            ? achievement.definition.titleRu
                            : achievement.definition.titleEn,
                        textAlign: TextAlign.center,
                        style: text.fraunces(size: 24, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: descriptionStage,
                    child: Text(
                      isRu
                          ? achievement.definition.descriptionRu
                          : achievement.definition.descriptionEn,
                      textAlign: TextAlign.center,
                      style: text.inter(
                        size: 12,
                        color: colors.fg2,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: completionStage,
                    child: Text(
                      achievement.unlockedAt == null
                          ? (isRu
                                ? achievement.definition.requirementRu
                                : achievement.definition.requirementEn)
                          : (isRu
                                ? 'Получено ${_date(achievement.unlockedAt!, true)}'
                                : 'Unlocked ${_date(achievement.unlockedAt!, false)}'),
                      textAlign: TextAlign.center,
                      style: text.mono(size: 8, color: colors.muted),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: BalanceMotion.standard,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .82, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String _number(double value) => value.roundToDouble() == value
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _date(DateTime value, bool isRu) => isRu
    ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
    : '${value.month}/${value.day}/${value.year}';
