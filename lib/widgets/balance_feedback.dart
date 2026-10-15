import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text_styles.dart';
import 'common.dart';

enum BalanceFeedbackType { success, info, warning, error, undo }

class BalanceFeedbackEvent {
  final BalanceFeedbackType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BalanceFeedbackEvent({
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}

class BalanceFeedbackHost extends StatefulWidget {
  final Widget child;

  const BalanceFeedbackHost({super.key, required this.child});

  static BalanceFeedbackHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<BalanceFeedbackHostState>();

  @override
  State<BalanceFeedbackHost> createState() => BalanceFeedbackHostState();
}

class BalanceFeedbackHostState extends State<BalanceFeedbackHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 200),
  );
  BalanceFeedbackEvent? _event;
  Timer? _hideTimer;
  int _generation = 0;

  void show(BalanceFeedbackEvent event) {
    _generation++;
    final generation = _generation;
    _hideTimer?.cancel();
    setState(() => _event = event);
    _controller.forward(from: 0);
    final hold = switch (event.type) {
      BalanceFeedbackType.success ||
      BalanceFeedbackType.info => const Duration(milliseconds: 1200),
      BalanceFeedbackType.undo => const Duration(milliseconds: 2800),
      BalanceFeedbackType.warning ||
      BalanceFeedbackType.error => const Duration(milliseconds: 3000),
    };
    _hideTimer = Timer(hold, () async {
      await _controller.reverse();
      if (mounted && generation == _generation) setState(() => _event = null);
    });
  }

  void success(String message) => show(
    BalanceFeedbackEvent(type: BalanceFeedbackType.success, message: message),
  );

  void info(String message) => show(
    BalanceFeedbackEvent(type: BalanceFeedbackType.info, message: message),
  );

  void warning(String message) => show(
    BalanceFeedbackEvent(type: BalanceFeedbackType.warning, message: message),
  );

  void error(String message) => show(
    BalanceFeedbackEvent(type: BalanceFeedbackType.error, message: message),
  );

  void undo({
    required String message,
    required String actionLabel,
    required VoidCallback onUndo,
  }) => show(
    BalanceFeedbackEvent(
      type: BalanceFeedbackType.undo,
      message: message,
      actionLabel: actionLabel,
      onAction: onUndo,
    ),
  );

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 18,
          right: 18,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: _event == null,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final value = Curves.easeOutCubic.transform(
                    _controller.value,
                  );
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: reduceMotion
                          ? Offset.zero
                          : Offset(0, -6 * (1 - value)),
                      child: Transform.scale(
                        scale: reduceMotion ? 1 : .98 + .02 * value,
                        child: _event == null
                            ? const SizedBox.shrink()
                            : _BalanceToast(
                                key: const ValueKey('balanceToast'),
                                event: _event!,
                                onAction: _handleAction,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleAction() {
    final action = _event?.onAction;
    if (action == null) return;
    HapticFeedback.selectionClick();
    action();
    _generation++;
    _hideTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) setState(() => _event = null);
    });
  }
}

class _BalanceToast extends StatelessWidget {
  final BalanceFeedbackEvent event;
  final VoidCallback onAction;

  const _BalanceToast({super.key, required this.event, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = AppText(colors);
    final accent = switch (event.type) {
      BalanceFeedbackType.success => colors.accent,
      BalanceFeedbackType.info => colors.macroCarb,
      BalanceFeedbackType.warning ||
      BalanceFeedbackType.error ||
      BalanceFeedbackType.undo => colors.accent2,
    };
    final icon = switch (event.type) {
      BalanceFeedbackType.success => Icons.check_rounded,
      BalanceFeedbackType.info => Icons.info_outline_rounded,
      BalanceFeedbackType.warning => Icons.priority_high_rounded,
      BalanceFeedbackType.error => Icons.close_rounded,
      BalanceFeedbackType.undo => Icons.delete_outline_rounded,
    };
    return RepaintBoundary(
      child: Material(
        color: colors.card.withValues(alpha: .97),
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.line.withValues(alpha: .8)),
            boxShadow: [
              BoxShadow(
                color: colors.fg.withValues(alpha: .08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .12),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.inter(size: 12, weight: FontWeight.w700),
                ),
              ),
              if (event.actionLabel != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  key: const ValueKey('balanceToastAction'),
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    event.actionLabel!,
                    style: text.inter(
                      size: 11,
                      weight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedDiaryEntry extends StatefulWidget {
  final Widget child;
  final bool animate;

  const AnimatedDiaryEntry({
    super.key,
    required this.child,
    required this.animate,
  });

  @override
  State<AnimatedDiaryEntry> createState() => _AnimatedDiaryEntryState();
}

class _AnimatedDiaryEntryState extends State<AnimatedDiaryEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.animate ||
          MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
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
      final value = Curves.easeOutCubic.transform(_controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}
