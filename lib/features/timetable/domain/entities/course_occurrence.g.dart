// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_occurrence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourseOccurrence _$CourseOccurrenceFromJson(Map<String, dynamic> json) =>
    _CourseOccurrence(
      courseName: json['courseName'] as String,
      teacher: json['teacher'] as String,
      location: json['location'] as String,
      credit: json['credit'] as String,
      courseType: json['courseType'] as String,
      stage: json['stage'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      startWeek: (json['startWeek'] as num?)?.toInt(),
      endWeek: (json['endWeek'] as num?)?.toInt(),
      weekText: json['weekText'] as String? ?? '',
      color: const ColorConverter().fromJson((json['color'] as num).toInt()),
    );

Map<String, dynamic> _$CourseOccurrenceToJson(_CourseOccurrence instance) =>
    <String, dynamic>{
      'courseName': instance.courseName,
      'teacher': instance.teacher,
      'location': instance.location,
      'credit': instance.credit,
      'courseType': instance.courseType,
      'stage': instance.stage,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'startWeek': instance.startWeek,
      'endWeek': instance.endWeek,
      'weekText': instance.weekText,
      'color': const ColorConverter().toJson(instance.color),
    };
