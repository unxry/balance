import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'common.dart';

class ProgressSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final List<Key> itemKeys;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool secondary;
  const ProgressSegmentedControl({
    super.key,
    required this.labels,
    required this.itemKeys,
    required this.selected,
    required this.onChanged,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText(c);
    final radius = secondary ? 16.0 : 21.0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card2.withValues(alpha: secondary ? .35 : .72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: c.line.withValues(alpha: secondary ? .25 : .55),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(-1 + 2 * selected / (labels.length - 1), 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: secondary ? c.surface : c.card,
                    borderRadius: BorderRadius.circular(radius - 5),
                    border: Border.all(
                      color: c.accent.withValues(alpha: secondary ? .1 : .18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.fg.withValues(alpha: secondary ? .025 : .055),
                        blurRadius: 9,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: Semantics(
                      selected: selected == index,
                      button: true,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          key: itemKeys[index],
                          borderRadius: BorderRadius.circular(radius - 5),
                          overlayColor: WidgetStatePropertyAll(
                            c.accent.withValues(alpha: .07),
                          ),
                          onTap: () => onChanged(index),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: secondary ? 44 : 48,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 10,
                              ),
                              child: Center(
                                child: Text(
                                  labels[index],
                                  textAlign: TextAlign.center,
                                  style: text.inter(
                                    size: secondary ? 11 : 12,
                                    weight: selected == index
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected == index ? c.accent : c.fg2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
