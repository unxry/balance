import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_forecast.dart';
import '../theme/app_text_styles.dart';
import 'common.dart';

class WeightForecastNote extends StatelessWidget {
  final WeightForecastSnapshot snapshot;
  final bool isRu;
  final bool active;
  final bool compact;
  final int? horizonDays;
  final int? displayedDays;
  final bool emptyPeriod;
  final bool limitedPeriod;
  final VoidCallback? onRetry;
  const WeightForecastNote({
    super.key,
    required this.snapshot,
    required this.isRu,
    required this.active,
    this.compact = false,
    this.horizonDays,
    this.displayedDays,
    this.emptyPeriod = false,
    this.limitedPeriod = false,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final title = active
        ? (isRu
              ? 'Прогноз · ${horizonDays ?? snapshot.horizonDays} дней'
              : 'Forecast · ${horizonDays ?? snapshot.horizonDays} days')
        : limitedPeriod && snapshot.ready
        ? (isRu ? 'Расширьте период графика' : 'Choose a wider chart period')
        : emptyPeriod && snapshot.ready
        ? (isRu ? 'Нет измерений за этот период' : 'No readings in this period')
        : snapshot.reason == 'storage'
        ? (isRu ? 'Прогноз пока недоступен' : 'Forecast unavailable')
        : snapshot.ready
        ? (isRu ? 'Нужны новые наблюдения' : 'More observations are needed')
        : snapshot.status == WeightForecastStatus.unreliable
        ? (isRu ? 'Тенденция пока неустойчива' : 'The trend is not stable yet')
        : (isRu
              ? 'Собираем данные для прогноза'
              : 'Gathering data for a forecast');
    final body = active
        ? '${isRu ? 'Темп рассчитан' : 'Rate calculated'} ${DateFormat('d MMM', isRu ? 'ru' : 'en').format(snapshot.calculatedAt!.toLocal())}. ${isRu ? 'Ориентир, а не обещание результата.' : 'An estimate, not a promised result.'}'
        : limitedPeriod && snapshot.ready
        ? (isRu
              ? 'Прогноз рассчитан. Здесь показаны только реальные измерения, чтобы сохранить читаемый масштаб.'
              : 'The forecast is available. This short range shows actual readings only to keep the scale readable.')
        : emptyPeriod && snapshot.ready
        ? (isRu
              ? 'Расширьте период, чтобы увидеть прогноз.'
              : 'Choose a wider period to see the forecast.')
        : snapshot.reason == 'storage'
        ? (isRu
              ? 'Повторите чтение локального расчёта.'
              : 'Try reading the local calculation again.')
        : snapshot.ready
        ? (isRu
              ? 'Прежний темп устарел или больше не подходит к записям. Добавьте новые измерения.'
              : 'The previous rate is outdated or no longer fits the readings. Add new measurements.')
        : snapshot.status == WeightForecastStatus.unreliable
        ? (isRu
              ? 'Измерения пока слишком разнятся для осторожной оценки.'
              : 'Readings vary too much for a cautious estimate.')
        : (isRu
              ? 'Добавляйте измерения веса, чтобы увидеть ориентировочную динамику. Нужны 4 дня с записями за неделю наблюдений.'
              : 'Add weight readings to see an approximate trend. We need 4 measured days across a week of observations.');
    return Container(
      key: ValueKey(active ? 'forecastReady' : 'forecastWaiting'),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: c.accentSoft.withValues(alpha: .26),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.auto_graph_rounded : Icons.timeline_rounded,
            color: c.accent,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 4),
                Text(body, style: t.inter(size: 10, color: c.fg2, height: 1.5)),
                if (active &&
                    displayedDays != null &&
                    displayedDays! < (horizonDays ?? snapshot.horizonDays)) ...[
                  const SizedBox(height: 4),
                  Text(
                    isRu
                        ? 'На графике — ближайшие $displayedDays дн., чтобы история оставалась читаемой.'
                        : 'The chart shows the next $displayedDays days to keep the history readable.',
                    style: t.inter(size: 9, color: c.fg2, height: 1.5),
                  ),
                ],
                if (active && snapshot.lowerSlope != null && !compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    isRu
                        ? 'Подложка — разброс оценок темпа при повторных выборках, не доверительный интервал веса.'
                        : 'The band shows variation in resampled trend estimates, not a confidence interval for weight.',
                    style: t.inter(size: 9, color: c.fg2, height: 1.5),
                  ),
                ],
                if (snapshot.reason == 'storage' && onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: Text(isRu ? 'Повторить' : 'Retry'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
