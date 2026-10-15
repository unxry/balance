import 'package:flutter/services.dart';

import '../models/food_product.dart';
import 'food_catalog_repository.dart';

enum CandidateConfidence { high, medium, low }

class PackagingTextFeatures {
  final String rawText;
  final String query;
  final String? brand;
  final String? productName;
  final String? variant;
  final double? fatPercent;
  final double? weightGrams;
  final double? volumeMl;

  const PackagingTextFeatures({
    required this.rawText,
    required this.query,
    this.brand,
    this.productName,
    this.variant,
    this.fatPercent,
    this.weightGrams,
    this.volumeMl,
  });

  factory PackagingTextFeatures.parse(String text) {
    final normalized = normalizeFoodText(text);
    final measurable = text.toLowerCase().replaceAll('ё', 'е');
    double? firstNumber(RegExp expression, {double multiplier = 1}) {
      final match = expression.firstMatch(measurable);
      final raw = match?.group(1)?.replaceAll(',', '.');
      final value = raw == null ? null : double.tryParse(raw);
      return value == null ? null : value * multiplier;
    }

    final kg = firstNumber(RegExp(r'(\d+(?:[.,]\d+)?)\s*кг(?:\s|$)'));
    final liters = firstNumber(RegExp(r'(\d+(?:[.,]\d+)?)\s*л(?:\s|$)'));
    final words = normalized
        .split(' ')
        .where(
          (word) =>
              word.length >= 2 &&
              !RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(word) &&
              !const {
                'ккал',
                'белки',
                'жиры',
                'углеводы',
                'пищевая',
                'ценность',
                'состав',
                'масса',
                'нетто',
              }.contains(word),
        )
        .take(10)
        .toList();
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map(normalizeFoodText)
        .where(
          (line) =>
              line.length >= 2 &&
              !RegExp(
                r'^(состав|пищевая ценность|белки|жиры|углеводы|ккал)',
              ).hasMatch(line),
        )
        .take(5)
        .toList();
    final variantWords = words
        .where(
          (word) => const {
            'клубника',
            'персик',
            'ваниль',
            'шоколад',
            'вишня',
            'малина',
            'черника',
            'яблоко',
            'банан',
            'классический',
            'натуральный',
          }.contains(word),
        )
        .join(' ');
    return PackagingTextFeatures(
      rawText: text,
      query: words.join(' '),
      brand: lines.isEmpty ? null : lines.first,
      productName: lines.isEmpty
          ? null
          : lines.length < 2
          ? lines.first
          : lines[1],
      variant: variantWords.isEmpty ? null : variantWords,
      fatPercent: firstNumber(RegExp(r'(\d+(?:[.,]\d+)?)\s*%')),
      weightGrams: kg == null
          ? firstNumber(RegExp(r'(\d+(?:[.,]\d+)?)\s*г(?:\s|$)'))
          : kg * 1000,
      volumeMl: liters == null
          ? firstNumber(RegExp(r'(\d+(?:[.,]\d+)?)\s*мл(?:\s|$)'))
          : liters * 1000,
    );
  }
}

class OcrProductCandidate {
  final FoodProduct product;
  final int score;
  final CandidateConfidence confidence;
  final List<String> evidence;

  const OcrProductCandidate({
    required this.product,
    required this.score,
    required this.confidence,
    required this.evidence,
  });
}

class PackageRecognitionService {
  PackageRecognitionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('balance/package_ocr');

  final MethodChannel _channel;

  Future<PackagingTextFeatures> recognize(String imagePath) async {
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'path': imagePath,
    });
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('No packaging text recognized');
    }
    return PackagingTextFeatures.parse(text);
  }

  Future<List<OcrProductCandidate>> findCandidates(
    PackagingTextFeatures features,
    FoodCatalogRepository repository, {
    int limit = 5,
  }) async {
    if (features.query.length < 2) return const [];
    final outcome = await repository.search(features.query, limit: 30);
    final candidates = <OcrProductCandidate>[];
    for (final product in outcome.items) {
      final evidence = <String>[];
      var score = 0;
      final recognized = normalizeFoodText(features.rawText);
      final nameTokens = product.normalizedName.split(' ');
      final matchedTokens = nameTokens
          .where((token) => token.length > 2 && recognized.contains(token))
          .length;
      score += matchedTokens * 12;
      if (matchedTokens > 0) evidence.add('name');

      final brand = normalizeFoodText(product.brand ?? '');
      final recognizedBrand = normalizeFoodText(features.brand ?? '');
      if (brand.isNotEmpty &&
          (recognized.contains(brand) || recognizedBrand == brand)) {
        score += 30;
        evidence.add('brand');
      }
      final recognizedName = normalizeFoodText(features.productName ?? '');
      if (recognizedName.isNotEmpty &&
          (product.normalizedName.contains(recognizedName) ||
              recognizedName.contains(product.normalizedName))) {
        score += 20;
        evidence.add('exactName');
      }
      final variant = normalizeFoodText(features.variant ?? '');
      if (variant.isNotEmpty && product.normalizedName.contains(variant)) {
        score += 18;
        evidence.add('variant');
      }
      if (_close(features.weightGrams, product.netWeightGrams) ||
          _close(features.volumeMl, product.netVolumeMl)) {
        score += 24;
        evidence.add('package');
      }
      if (features.fatPercent != null &&
          product.normalizedName.contains(
            _compactNumber(features.fatPercent!),
          )) {
        score += 18;
        evidence.add('variant');
      }
      if (product.retailerTags.any(
        (retailer) => recognized.contains(normalizeFoodText(retailer)),
      )) {
        score += 8;
        evidence.add('retailer');
      }
      score += switch (product.dataQuality) {
        FoodDataQuality.verified => 14,
        FoodDataQuality.good => 8,
        FoodDataQuality.partial => 3,
        FoodDataQuality.unverified => 0,
      };
      final previousUse = await repository.useCount(product);
      if (previousUse > 0) {
        score += 10;
        evidence.add('previouslyUsed');
      }
      candidates.add(
        OcrProductCandidate(
          product: product,
          score: score,
          confidence: score >= 65
              ? CandidateConfidence.high
              : score >= 35
              ? CandidateConfidence.medium
              : CandidateConfidence.low,
          evidence: evidence,
        ),
      );
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(limit.clamp(1, 5)).toList();
  }

  static bool _close(double? expected, double? actual) {
    if (expected == null || actual == null) return false;
    return (expected - actual).abs() <= expected * 0.08 + 2;
  }

  static String _compactNumber(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

abstract interface class VisualProductMatcher {
  Future<List<OcrProductCandidate>> match(String imagePath);
}
