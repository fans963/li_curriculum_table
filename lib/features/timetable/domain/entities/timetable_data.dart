import 'course_occurrence.dart';
import 'course_row.dart';

class TimetableData {
  const TimetableData({
    required this.rows,
    required this.occurrences,
    required this.loginLikelySuccess,
  });

  final List<CourseRow> rows;
  final List<CourseOccurrence> occurrences;
  final bool loginLikelySuccess;
}
