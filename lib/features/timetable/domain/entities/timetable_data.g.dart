// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimetableData _$TimetableDataFromJson(Map<String, dynamic> json) =>
    _TimetableData(
      rows: (json['rows'] as List<dynamic>)
          .map((e) => CourseRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      occurrences: (json['occurrences'] as List<dynamic>)
          .map((e) => CourseOccurrence.fromJson(e as Map<String, dynamic>))
          .toList(),
      loginLikelySuccess: json['loginLikelySuccess'] as bool,
    );

Map<String, dynamic> _$TimetableDataToJson(_TimetableData instance) =>
    <String, dynamic>{
      'rows': instance.rows,
      'occurrences': instance.occurrences,
      'loginLikelySuccess': instance.loginLikelySuccess,
    };
