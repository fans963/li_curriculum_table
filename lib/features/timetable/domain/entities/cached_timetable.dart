import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';

class CachedTimetable {
  const CachedTimetable({required this.rows, required this.cachedAt});

  final List<CourseRow> rows;
  final DateTime cachedAt;
}
