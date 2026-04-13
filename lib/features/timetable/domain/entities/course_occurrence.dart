import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_occurrence.freezed.dart';
part 'course_occurrence.g.dart';

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color object) => object.toARGB32();
}

@freezed
abstract class CourseOccurrence with _$CourseOccurrence {
  const factory CourseOccurrence({
    required String courseName,
    required String teacher,
    required String location,
    required String credit,
    required String courseType,
    required String stage,
    required DateTime start,
    required DateTime end,
    int? startWeek,
    int? endWeek,
    @Default('') String weekText,
    @ColorConverter() required Color color,
  }) = _CourseOccurrence;

  factory CourseOccurrence.fromJson(Map<String, dynamic> json) =>
      _$CourseOccurrenceFromJson(json);
}
