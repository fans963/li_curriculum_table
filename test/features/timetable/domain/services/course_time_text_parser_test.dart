import 'package:flutter_test/flutter_test.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_time_text_parser.dart';

void main() {
  group('parseCourseTimeSlots', () {
    test('parses multi-slot text with mixed week ranges', () {
      const text = '1-3,5周 星期三(01-03小节)6周 星期三(02-03小节)';

      final result = parseCourseTimeSlots(text);

      expect(result.length, 2);

      expect(result[0].weekday, DateTime.wednesday);
      expect(result[0].startSection, 1);
      expect(result[0].endSection, 3);
      expect(result[0].startWeek, 1);
      expect(result[0].endWeek, 5);

      expect(result[1].weekday, DateTime.wednesday);
      expect(result[1].startSection, 2);
      expect(result[1].endSection, 3);
      expect(result[1].startWeek, 6);
      expect(result[1].endWeek, 6);
    });

    test('returns empty when no slot match exists', () {
      final result = parseCourseTimeSlots('无效文本');
      expect(result, isEmpty);
    });
  });
}
