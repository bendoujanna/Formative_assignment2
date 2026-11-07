import 'package:campus_incident_app/core/date_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 6, 12, 0);

  group('timeAgo', () {
    test('under a minute is Just now', () {
      expect(
        timeAgo(now.subtract(const Duration(seconds: 20)), now: now),
        'Just now',
      );
    });

    test('minutes', () {
      expect(
        timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
    });

    test('hours, singular and plural', () {
      expect(
        timeAgo(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3 hours ago',
      );
    });

    test('days, singular and plural', () {
      expect(
        timeAgo(now.subtract(const Duration(days: 1)), now: now),
        '1 day ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
    });

    test('a week or more shows the date', () {
      expect(
        timeAgo(now.subtract(const Duration(days: 10)), now: now),
        'Oct 27, 2026',
      );
    });

    test('a time slightly in the future is treated as Just now', () {
      expect(
        timeAgo(now.add(const Duration(minutes: 2)), now: now),
        'Just now',
      );
    });
  });
}
