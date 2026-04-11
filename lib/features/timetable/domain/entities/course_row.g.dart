// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseRow _$CourseRowFromJson(Map<String, dynamic> json) => _CourseRow(
  courseId: json['courseId'] as String,
  order: json['order'] as String,
  courseName: json['courseName'] as String,
  teacher: json['teacher'] as String,
  timeText: json['timeText'] as String,
  credit: json['credit'] as String,
  location: json['location'] as String,
  courseType: json['courseType'] as String,
  stage: json['stage'] as String,
  slots: (json['slots'] as List<dynamic>)
      .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CourseRowToJson(_CourseRow instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'order': instance.order,
      'courseName': instance.courseName,
      'teacher': instance.teacher,
      'timeText': instance.timeText,
      'credit': instance.credit,
      'location': instance.location,
      'courseType': instance.courseType,
      'stage': instance.stage,
      'slots': instance.slots,
    };
