/// Calendar-day helpers deliberately compare local civil dates rather than
/// elapsed 24-hour periods. This keeps daily state correct across DST changes
/// and makes the year part of every comparison.
String localDateKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String? storedLocalDateKey(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  final keyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
  if (keyMatch != null) {
    final year = int.tryParse(keyMatch.group(1)!);
    final month = int.tryParse(keyMatch.group(2)!);
    final day = int.tryParse(keyMatch.group(3)!);
    if (_isValidDate(year, month, day)) return trimmed;
    return null;
  }
  final parsed = DateTime.tryParse(trimmed);
  return parsed == null ? null : localDateKey(parsed);
}

bool isSameLocalCalendarDay(DateTime a, DateTime b) =>
    localDateKey(a) == localDateKey(b);

int calendarDayDifference(String newerKey, String olderKey) {
  final newer = _parseKey(newerKey);
  final older = _parseKey(olderKey);
  if (newer == null || older == null) return 0;
  return DateTime.utc(
    newer.$1,
    newer.$2,
    newer.$3,
  ).difference(DateTime.utc(older.$1, older.$2, older.$3)).inDays;
}

(int, int, int)? _parseKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (!_isValidDate(year, month, day)) return null;
  return (year!, month!, day!);
}

bool _isValidDate(int? year, int? month, int? day) {
  if (year == null || month == null || day == null) return false;
  if (year < 1970 || year > 9999 || month < 1 || month > 12 || day < 1) {
    return false;
  }
  final candidate = DateTime.utc(year, month, day);
  return candidate.year == year &&
      candidate.month == month &&
      candidate.day == day;
}
