import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_tip.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import 'common.dart';
import 'tip_sources_panel.dart';

IconData tipIcon(TipCategory category) => switch (category) {
  TipCategory.nutrition => Icons.restaurant_outlined,
  TipCategory.macros => Icons.grain_rounded,
  TipCategory.hydration => Icons.water_drop_outlined,
  TipCategory.activity => Icons.directions_walk_rounded,
  TipCategory.recovery => Icons.bedtime_outlined,
  TipCategory.habits => Icons.repeat_rounded,
  TipCategory.mindful => Icons.spa_outlined,
  TipCategory.progress => Icons.show_chart_rounded,
  TipCategory.facts => Icons.lightbulb_outline_rounded,
  TipCategory.today => Icons.wb_sunny_outlined,
};

Future<void> tipAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    final ru = context.read<SettingsProvider>().lang == AppLang.ru;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ru
              ? 'Не удалось сохранить. Попробуйте ещё раз.'
              : 'Could not save. Please try again.',
        ),
      ),
    );
  }
}

class DailyTipCard extends StatefulWidget {
  final DailyTip tip;
  final TipVisit visit;
  final bool assigned;
  const DailyTipCard({
    super.key,
    required this.tip,
    required this.visit,
    this.assigned = true,
  });
  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  bool _showTask = false;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant DailyTipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tip.id != widget.tip.id ||
        oldWidget.visit.dateKey != widget.visit.dateKey) {
      _showTask = false;
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await tipAction(context, action);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = AppText(c);
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final data = context.watch<AppDataProvider>();
    final suitable = data.dailyTips.isSuitable(widget.tip);
    final copy = suitable
        ? widget.tip.copy(ru)
        : TipCopy(
            ru ? 'Сейчас — общая поддержка' : 'General support for now',
            ru
                ? 'Цель или ограничения изменились. Этот материал о снижении веса сейчас не подходит; дальнейшие ограничения не предлагаются.'
                : 'Your goal or safety context changed. This weight-loss material is currently unsuitable; further restriction is not suggested.',
          );
    final saved = data.dailyTips.saved.contains(widget.tip.id);
    final completed = data.dailyTips.history.any(
      (v) => v.dateKey == widget.visit.dateKey && v.completed,
    );
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: SectionCard(
        key: ValueKey('dailyTip-${widget.tip.id}'),
        radius: 28,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    tipIcon(widget.tip.category),
                    color: c.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MonoLabel(ru ? 'СОВЕТ ДНЯ' : 'TIP OF THE DAY', size: 9),
                      const SizedBox(height: 4),
                      Text(
                        widget.tip.category.label(ru),
                        style: text.inter(
                          size: 12,
                          color: c.accent,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('saveTip-${widget.tip.id}'),
                  tooltip: saved
                      ? (ru ? 'Убрать из сохранённых' : 'Remove from saved')
                      : (ru ? 'Сохранить' : 'Save'),
                  isSelected: saved,
                  onPressed: _busy
                      ? null
                      : () => _act(() => data.toggleSavedTip(widget.tip.id)),
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: c.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              copy.title,
              style: text.fraunces(
                size: 28,
                weight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              copy.body,
              style: text.inter(size: 14, color: c.fg2, height: 1.6),
            ),
            if (widget.tip.retired) ...[
              const SizedBox(height: 10),
              Text(
                ru
                    ? 'Материал обновлён; прежний идентификатор, история и избранное сохранены.'
                    : 'Content updated; the previous ID, history and saved status are preserved.',
                style: text.inter(size: 10, color: c.muted),
              ),
            ],
            if (copy.explanation != null) ...[
              const SizedBox(height: 18),
              Text(
                ru ? 'Что происходит?' : 'What is happening?',
                style: text.inter(size: 13, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                copy.explanation!,
                style: text.inter(size: 13, color: c.fg2, height: 1.6),
              ),
            ],
            if (widget.visit.basis != TipBasis.universal &&
                widget.assigned) ...[
              const SizedBox(height: 18),
              Text(
                ru
                    ? 'Почему Balance показывает этот совет'
                    : 'Why Balance shows this advice',
                style: text.inter(size: 13, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                (ru ? widget.visit.reasonRu : widget.visit.reasonEn) ??
                    (ru
                        ? 'Основание старой записи не сохранено; новые причины не приписываются.'
                        : 'The old assignment has no saved rationale; new reasons are not invented.'),
                style: text.inter(size: 12, color: c.fg2, height: 1.5),
              ),
              Text(
                ru
                    ? 'Основание относится к дате назначения; после правок записей актуальную оценку смотрите в анализе динамики.'
                    : 'This rationale describes the assignment date; after edits, see the trend page for the current assessment.',
                style: text.inter(size: 10, color: c.muted, height: 1.5),
              ),
            ],
            if (copy.why != null) ...[
              const SizedBox(height: 20),
              Text(
                ru ? 'Почему такое бывает?' : 'Why might this happen?',
                style: text.inter(size: 12, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                copy.why!,
                style: text.inter(size: 12, color: c.fg2, height: 1.5),
              ),
            ],
            if (copy.task != null) ...[
              const SizedBox(height: 22),
              if (!_showTask && !completed)
                OutlinedButton.icon(
                  key: ValueKey('tryTip-${widget.tip.id}'),
                  onPressed: () => setState(() => _showTask = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.accent,
                    side: BorderSide(color: c.accent.withValues(alpha: .3)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 17),
                  label: Text(
                    ru ? 'Попробовать сегодня' : 'Try it today',
                    style: text.inter(
                      size: 12,
                      color: c.accent,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              if ((_showTask || completed) && !widget.assigned)
                Text(copy.task!, style: text.inter(size: 13, height: 1.5)),
              if ((_showTask || completed) && widget.assigned)
                Material(
                  color: c.accentSoft.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(18),
                  child: CheckboxListTile(
                    key: ValueKey('completeTip-${widget.visit.dateKey}'),
                    value: completed,
                    activeColor: c.accent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      copy.task!,
                      style: text.inter(size: 12, height: 1.45),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        completed
                            ? (widget.visit.catalogVersion < widget.tip.version
                                  ? (ru
                                        ? 'Отметка прежней версии сохранена'
                                        : 'Previous content completion preserved')
                                  : (ru ? 'Выполнено' : 'Completed'))
                            : (ru
                                  ? 'Отметьте, когда сделаете'
                                  : 'Check when you have done it'),
                        style: text.inter(size: 10, color: c.fg2),
                      ),
                    ),
                    onChanged: _busy
                        ? null
                        : (value) => _act(
                            () => data.setTipCompleted(
                              widget.visit.dateKey,
                              value ?? false,
                            ),
                          ),
                  ),
                ),
            ],
            const SizedBox(height: 22),
            TipSourcesPanel(
              sourceIds: suitable
                  ? widget.tip.sourceIds
                  : const ['niddk-planner'],
            ),
          ],
        ),
      ),
    );
  }
}
