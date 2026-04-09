import 'package:flutter_test/flutter_test.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_inference.dart';

void main() {
  group('inferTeachingWeekFromBaseline', () {
    test('returns same week when today equals reference date', () {
      final inferred = inferTeachingWeekFromBaseline(
        referenceDate: DateTime(2026, 4, 9),
        referenceWeek: 6,
        today: DateTime(2026, 4, 9),
      );

      expect(inferred, 6);
    });

    test('increments week every 7 days', () {
      final inferred = inferTeachingWeekFromBaseline(
        referenceDate: DateTime(2026, 4, 9),
        referenceWeek: 6,
        today: DateTime(2026, 4, 23),
      );

      expect(inferred, 8);
    });

    test('never returns less than week 1', () {
      final inferred = inferTeachingWeekFromBaseline(
        referenceDate: DateTime(2026, 4, 9),
        referenceWeek: 1,
        today: DateTime(2026, 1, 1),
      );

      expect(inferred, 1);
    });
  });
}
