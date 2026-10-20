import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/tip_sources.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import 'common.dart';

class TipSourcesPanel extends StatelessWidget {
  final List<String> sourceIds;
  const TipSourcesPanel({super.key, required this.sourceIds});
  @override
  Widget build(BuildContext context) {
    final ru = context.watch<SettingsProvider>().lang == AppLang.ru;
    final t = AppText(context.colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ru ? 'На чём основан совет' : 'What supports this advice',
          style: t.inter(size: 13, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        for (final id in sourceIds)
          if (tipSources[id] case final source?) ...[
            TextButton.icon(
              key: ValueKey('tipSource-$id'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: context.colors.accent,
              ),
              label: Text(
                source.title,
                style: t.inter(size: 12, color: context.colors.accent),
              ),
              onPressed: () async {
                var ok = false;
                try {
                  ok = await launchUrl(
                    Uri.parse(source.url),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {}
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ru
                            ? 'Для открытия источника нужен доступ к интернету.'
                            : 'Internet access is needed to open this source.',
                      ),
                    ),
                  );
                }
              },
            ),
            Text(
              ru ? source.scopeRu : source.scopeEn,
              style: t.inter(size: 10, color: context.colors.fg2, height: 1.5),
            ),
            Text(
              '${ru ? 'Проверено' : 'Checked'} ${source.checkedOn}',
              style: t.inter(size: 9, color: context.colors.muted),
            ),
            const SizedBox(height: 8),
          ],
        Text(
          ru
              ? 'Материал сверён с источниками; независимая клиническая экспертиза ещё не проводилась. Учитывайте аллергию и назначенную лечебную диету.'
              : 'Content was checked against sources; independent clinical review is pending. Account for allergies and any prescribed diet.',
          style: t.inter(size: 10, color: context.colors.fg2, height: 1.5),
        ),
      ],
    );
  }
}
