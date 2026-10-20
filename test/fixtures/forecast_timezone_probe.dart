import 'dart:convert';
import 'dart:io';
import 'package:flutter_app/models/history_models.dart';
import 'package:flutter_app/services/weight_forecast_cache.dart';

Future<void> main(List<String> args) async {
  final file = File(args.single);
  Object? stored = file.existsSync()
      ? jsonDecode(file.readAsStringSync())
      : null;
  final cache = WeightForecastCache(
    read: () => stored,
    write: (value) async {
      stored = value;
      await file.writeAsString(jsonEncode(value));
    },
  );
  final entries = [
    for (final d in [0, 2, 4, 6])
      WeightEntry(
        id: 'w$d',
        date: DateTime.utc(2026, 12, 25 + d, 22, 30),
        kg: 80 - d * .06,
      ),
  ];
  final now = DateTime.utc(2027, 1, 1, 20);
  final value = await cache.refresh(weights: entries, now: now);
  stdout.writeln(
    jsonEncode({
      'offset': entries.first.date.toLocal().timeZoneOffset.inMinutes,
      'hash': value.sourceHash,
      'calculations': cache.calculationCount,
      'ready': value.ready,
    }),
  );
}
