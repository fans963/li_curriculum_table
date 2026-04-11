import 'package:freezed_annotation/freezed_annotation.dart';
import 'course_occurrence.dart';
import 'course_row.dart';

part 'timetable_data.freezed.dart';
part 'timetable_data.g.dart';

@freezed
abstract class TimetableData with _$TimetableData {
  const factory TimetableData({
    required List<CourseRow> rows,
    required List<CourseOccurrence> occurrences,
    required bool loginLikelySuccess,
  }) = _TimetableData;

  factory TimetableData.fromJson(Map<String, dynamic> json) =>
      _$TimetableDataFromJson(json);
}
