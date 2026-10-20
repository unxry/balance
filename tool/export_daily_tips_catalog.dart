import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/data/daily_tips_catalog.dart';
import 'package:flutter_app/data/tip_sources.dart';
import 'package:flutter_app/models/daily_tip.dart';

Map<String, Object?> tipCopySnapshot(TipCopy copy) => {
  'title': copy.title,
  'summary': copy.body,
  'action': copy.task,
  'steps': copy.steps,
  'example': copy.example,
  'alternative': copy.alternative,
  'doneWhen': copy.doneWhen,
  'benefit': copy.why,
  'background': copy.explanation,
};

Map<String, Object?> dailyTipsCatalogSnapshot() => {
  'schemaVersion': 1,
  'edition': '3.1',
  'activeCount': activeDailyTips.length,
  'universalCount': activeDailyTips
      .where((t) => t.basis == TipBasis.universal)
      .length,
  'plans': [
    for (final tip in activeDailyTips)
      {
        'id': tip.id,
        'category': tip.category.name,
        'topic': tip.topicKey,
        'version': tip.version,
        'destination': tip.destination.name,
        'context': {'ru': tip.ru.body, 'en': tip.en.body},
        'localizations': {
          'ru': tipCopySnapshot(tip.ru),
          'en': tipCopySnapshot(tip.en),
        },
        'applicability': {
          'basis': tip.basis.name,
          'requiredSignals': tip.requiredSignals,
          'eligibilityRules': tip.eligibilityRules,
          'weightManagementOnly': tip.weightManagementOnly,
          'usesLoggedMacros': tip.usesLoggedMacros,
          'contraindicationRules': tip.contraindicationRules,
          'safetyTags': tip.safetyTags,
        },
        'evidenceLevel': tip.evidenceLevel.name,
        'sourceIds': tip.sourceIds,
      },
  ],
  'legacyAliases': legacyTipAliases,
  'preservedLegacyContent': preservedLegacyContent,
  'retiredCopies': [
    for (final tip in retiredDailyTips)
      {
        'id': tip.id,
        'canonicalId': tip.canonicalId,
        'version': tip.version,
        'localizations': {
          'ru': tipCopySnapshot(tip.ru),
          'en': tipCopySnapshot(tip.en),
        },
      },
  ],
  'sources': [
    for (final source in tipSources.values)
      {
        'id': source.id,
        'title': source.title,
        'url': source.url,
        'checkedOn': source.checkedOn,
        'scope': {'ru': source.scopeRu, 'en': source.scopeEn},
      },
  ],
};

void main(List<String> args) {
  final path = args.isEmpty ? 'docs/daily_tips_catalog.json' : args.single;
  File(path).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(dailyTipsCatalogSnapshot())}\n',
  );
}
