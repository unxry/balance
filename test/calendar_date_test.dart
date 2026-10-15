import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/utils/calendar_date.dart';

void main() {
  test('date keys include the year', () {
    expect(
      isSameLocalCalendarDay(DateTime(2025, 8, 29), DateTime(2026, 8, 29)),
      isFalse,
    );
  });

  test('calendar difference handles 31 December to 1 January', () {
    expect(calendarDayDifference('2026-01-01', '2025-12-31'), 1);
  });

  test('calendar difference is DST-safe because it uses UTC civil dates', () {
    expect(calendarDayDifference('2026-03-30', '2026-03-29'), 1);
    expect(calendarDayDifference('2026-10-26', '2026-10-25'), 1);
  });

  test('legacy ISO values migrate to a valid local calendar key', () {
    final value = storedLocalDateKey('2026-08-29T23:50:00');
    expect(value, '2026-08-29');
    expect(storedLocalDateKey('2026-02-31'), isNull);
  });
}
