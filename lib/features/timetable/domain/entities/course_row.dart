import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;
import 'time_slot.dart';

part 'course_row.freezed.dart';
part 'course_row.g.dart';

@freezed
abstract class CourseRow with _$CourseRow {
  const factory CourseRow({
    required String courseId,
    required String order,
    required String courseName,
    required String teacher,
    required String timeText,
    required String credit,
    required String location,
    required String courseType,
    required String stage,
    required List<TimeSlot> slots,
  }) = _CourseRow;

  factory CourseRow.fromRust(rust_model.CourseRow row) {
    return CourseRow(
      courseId: row.courseId,
      order: row.order,
      courseName: row.courseName,
      teacher: row.teacher,
      timeText: row.timeText,
      credit: row.credit,
      location: row.location,
      courseType: row.courseType,
      stage: row.stage,
      slots: row.slots.map((s) => TimeSlot.fromRust(s)).toList(),
    );
  }

  factory CourseRow.fromJson(Map<String, dynamic> json) =>
      _$CourseRowFromJson(json);
}
