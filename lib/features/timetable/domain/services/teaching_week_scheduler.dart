import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';

DateTime mondayOfDate(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - DateTime.monday));
}

DateTime mondayOfTermWeekOne({required int currentTeachingWeek}) {
  final safeWeek = currentTeachingWeek < 1 ? 1 : currentTeachingWeek;
  final todayMonday = mondayOfDate(DateTime.now());
  return todayMonday.subtract(Duration(days: (safeWeek - 1) * 7));
}

List<CourseOccurrence> spreadOccurrencesByTeachingWeek({
  required List<CourseOccurrence> templates,
  required int currentTeachingWeek,
}) {
  if (templates.isEmpty) {
    return const <CourseOccurrence>[];
  }

  final termWeekOneMonday = mondayOfTermWeekOne(
    currentTeachingWeek: currentTeachingWeek,
  );
  final result = <CourseOccurrence>[];

  for (final occurrence in templates) {
    final weeks = _resolveWeeks(occurrence, currentTeachingWeek);
    for (final week in weeks) {
      final targetDate = termWeekOneMonday.add(
        Duration(days: (week - 1) * 7 + (occurrence.start.weekday - 1)),
      );
      final start = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        occurrence.start.hour,
        occurrence.start.minute,
      );
      var end = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        occurrence.end.hour,
        occurrence.end.minute,
      );
      if (!end.isAfter(start)) {
        end = end.add(const Duration(days: 1));
      }

      result.add(
        CourseOccurrence(
          courseName: occurrence.courseName,
          teacher: occurrence.teacher,
          location: occurrence.location,
          credit: occurrence.credit,
          courseType: occurrence.courseType,
          stage: occurrence.stage,
          start: start,
          end: end,
          startWeek: occurrence.startWeek,
          endWeek: occurrence.endWeek,
          weekText: occurrence.weekText,
          color: occurrence.color,
        ),
      );
    }
  }

  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}

List<int> _resolveWeeks(CourseOccurrence occurrence, int currentTeachingWeek) {
  final startWeek = occurrence.startWeek;
  final endWeek = occurrence.endWeek;
  if (startWeek == null || endWeek == null) {
    final safe = currentTeachingWeek < 1 ? 1 : currentTeachingWeek;
    return <int>[safe];
  }

  final a = startWeek < endWeek ? startWeek : endWeek;
  final b = startWeek < endWeek ? endWeek : startWeek;
  return List<int>.generate(b - a + 1, (index) => a + index);
}
