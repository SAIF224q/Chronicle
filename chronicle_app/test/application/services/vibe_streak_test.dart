import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';

void main() {
  group('TimelineService.calculateStreak', () {
    test('returns 0 for empty active dates', () {
      final now = DateTime(2026, 6, 28);
      final streak = TimelineService.calculateStreak([], now);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });

    test('calculates active streak when entry exists today', () {
      final now = DateTime(2026, 6, 28);
      final activeDates = [
        '2026-06-28',
        '2026-06-27',
        '2026-06-26',
        '2026-06-24', // Gap here
      ];
      final streak = TimelineService.calculateStreak(activeDates, now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('calculates active streak when entry exists yesterday but not today', () {
      final now = DateTime(2026, 6, 28);
      final activeDates = [
        '2026-06-27',
        '2026-06-26',
        '2026-06-25',
      ];
      final streak = TimelineService.calculateStreak(activeDates, now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('calculates streak 0 when entry exists only in past (gap > 1 day)', () {
      final now = DateTime(2026, 6, 28);
      final activeDates = [
        '2026-06-26',
        '2026-06-25',
      ];
      final streak = TimelineService.calculateStreak(activeDates, now);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 2);
    });

    test('computes longest streak historically larger than current streak', () {
      final now = DateTime(2026, 6, 28);
      final activeDates = [
        '2026-06-28',
        '2026-06-27', // Current streak = 2
        '2026-06-25',
        '2026-06-24',
        '2026-06-23',
        '2026-06-22',
        '2026-06-21', // Historical streak = 5
      ];
      final streak = TimelineService.calculateStreak(activeDates, now);
      expect(streak.currentStreak, 2);
      expect(streak.longestStreak, 5);
    });
  });
}
