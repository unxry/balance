import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_tip.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import 'common.dart';
import 'tip_sources_panel.dart';
import 'tip_navigation.dart';

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
  bool _showTask = false, _showAlternative = false, _busy = false;
  @override
  void didUpdateWidget(covariant DailyTipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tip.id != widget.tip.id ||
        oldWidget.visit.dateKey != widget.visit.dateKey) {
      _showTask = false;
      _showAlternative = false;
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
    final c = context.colors, t = AppText(context.colors);
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final data = context.watch<AppDataProvider>();
    final original = data.dailyTips.tipById(widget.tip.id) ?? widget.tip;
    final suitable = data.dailyTips.isSuitable(original);
    final effective = suitable
        ? widget.tip
        : data.dailyTips.tipById('care-context')!;
    final copy = effective.copy(ru);
    final saved = data.dailyTips.saved.contains(widget.tip.id);
    final chosen = data.dailyTips.displayVisit;
    final assigned = widget.assigned || chosen?.tipId == widget.tip.id;
    final visit = !widget.assigned && chosen?.tipId == widget.tip.id
        ? chosen!
        : widget.visit;
    final completed = data.dailyTips.readingHistory.any(
      (v) =>
          v.dateKey == visit.dateKey && v.tipId == visit.tipId && v.completed,
    );
    Widget block(String title, String body, {bool primary = false, Key? key}) =>
        Container(
          key: key,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary
                ? c.accentSoft.withValues(alpha: .65)
                : c.page.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.inter(
                  size: 11,
                  weight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                body,
                style: t.inter(
                  size: primary ? 17 : 13,
                  weight: primary ? FontWeight.w600 : FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
    return SectionCard(
      key: ValueKey('dailyTip-${widget.tip.id}'),
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tipIcon(effective.category), color: c.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  effective.category.label(ru),
                  style: t.inter(size: 12, color: c.accent),
                ),
              ),
              IconButton(
                key: ValueKey('saveTip-${widget.tip.id}'),
                tooltip: saved
                    ? (ru ? 'Убрать из сохранённых' : 'Remove from saved')
                    : (ru ? 'Сохранить' : 'Save'),
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
          const SizedBox(height: 12),
          Text(
            copy.title,
            style: t.fraunces(size: 26, weight: FontWeight.w700, height: 1.15),
          ),
          const SizedBox(height: 9),
          Text(copy.body, style: t.inter(size: 13, color: c.fg2, height: 1.5)),
          if (copy.task != null)
            block(
              ru ? 'Что сделать сегодня' : 'One action today',
              copy.task!,
              primary: true,
              key: ValueKey('todayAction-${widget.tip.id}'),
            ),
          if (copy.example != null)
            block(
              ru ? 'Например' : 'For example',
              _showAlternative && copy.alternative != null
                  ? copy.alternative!
                  : copy.example!,
            ),
          if (copy.alternative != null)
            TextButton.icon(
              key: ValueKey('tipSubstitute-${widget.tip.id}'),
              onPressed: () =>
                  setState(() => _showAlternative = !_showAlternative),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                _showAlternative
                    ? (ru ? 'Вернуть пример' : 'Original example')
                    : (ru ? 'Более простой вариант' : 'Another way to do it'),
              ),
            ),
          if (copy.why != null)
            block(
              ru ? 'Почему это может помочь' : 'Why this may help',
              copy.why!,
            ),
          if (copy.task != null) ...[
            const SizedBox(height: 14),
            if (!_showTask && !completed)
              OutlinedButton.icon(
                key: ValueKey('tryTip-${widget.tip.id}'),
                onPressed: () => setState(() => _showTask = true),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(ru ? 'Попробовать сегодня' : 'Try today'),
              ),
            if (_showTask || completed) ...[
              if (copy.steps.isNotEmpty) ...[
                Text(
                  ru ? 'Как это сделать' : 'How to do it',
                  style: t.inter(size: 13, weight: FontWeight.w600),
                ),
                for (var i = 0; i < copy.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}.',
                          style: t.inter(size: 13, color: c.accent),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            copy.steps[i],
                            style: t.inter(size: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (copy.doneWhen != null)
                block(ru ? 'Готово, когда' : 'Done when', copy.doneWhen!),
              if (assigned)
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    key: ValueKey('completeTip-${visit.dateKey}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: c.accent,
                    value: suitable && completed,
                    title: Text(
                      !suitable
                          ? (ru
                                ? 'Исходное действие сейчас не подходит'
                                : 'The original action is currently unsuitable')
                          : completed &&
                                visit.completionVersion < widget.tip.version
                          ? (ru
                                ? 'Отметка прежней версии сохранена'
                                : 'Previous content completion preserved')
                          : (completed
                                ? (ru ? 'Выполнено' : 'Completed')
                                : (ru
                                      ? 'Я выполнил(а) действие'
                                      : 'I did this action')),
                      style: t.inter(size: 13),
                    ),
                    onChanged: _busy || !suitable
                        ? null
                        : (v) => _act(
                            () => data.setTipCompleted(
                              visit.dateKey,
                              v ?? false,
                              tipId: visit.tipId,
                            ),
                          ),
                  ),
                ),
            ],
          ],
          if ((!widget.assigned || !suitable) &&
              chosen?.tipId != effective.id &&
              data.dailyTips.canChoose(effective.id))
            FilledButton.icon(
              key: ValueKey('useTipToday-${effective.id}'),
              onPressed: _busy
                  ? null
                  : () async {
                      await _act(() => data.chooseTipAlternative(effective.id));
                      if (mounted &&
                          data.dailyTips.displayVisit?.tipId == effective.id) {
                        setState(() => _showTask = true);
                      }
                    },
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(
                ru ? 'Выбрать на сегодня' : 'Make this today’s action',
              ),
            ),
          if (effective.destination != TipDestination.none)
            TextButton.icon(
              key: ValueKey('tipDestination-${widget.tip.id}'),
              onPressed: () =>
                  openTipDestination(context, effective.destination),
              icon: Icon(
                effective.destination == TipDestination.food
                    ? Icons.menu_book_outlined
                    : Icons.show_chart_rounded,
              ),
              label: Text(
                effective.destination == TipDestination.food
                    ? (ru ? 'Открыть дневник' : 'Open food diary')
                    : (effective.destination == TipDestination.insights
                          ? (ru ? 'Проверить динамику' : 'Review the trend')
                          : (ru ? 'Открыть графики' : 'Open graphs')),
              ),
            ),
          if (suitable && assigned && widget.visit.basis != TipBasis.universal)
            block(
              ru ? 'Почему показан этот совет' : 'Why this was shown',
              '${(ru ? widget.visit.reasonRu : widget.visit.reasonEn) ?? (ru ? 'У старой записи нет сохранённого основания.' : 'No rationale was saved for this old assignment.')} ${ru ? 'Это контекст даты назначения; текущие данные смотрите в анализе.' : 'This describes the assignment date; insights show current data.'}',
            ),
          if (widget.tip.retired)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                ru
                    ? 'Материал обновлён. Прежний ID, история и сохранение остаются.'
                    : 'Updated content. The previous ID, history and saved status remain.',
                style: t.inter(size: 10, color: c.muted),
              ),
            ),
          const SizedBox(height: 12),
          Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                ru ? 'Объяснение и источники' : 'Background and sources',
                style: t.inter(size: 12, color: c.accent),
              ),
              children: [
                if (copy.explanation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      copy.explanation!,
                      style: t.inter(size: 12, color: c.fg2, height: 1.5),
                    ),
                  ),
                TipSourcesPanel(sourceIds: effective.sourceIds),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
