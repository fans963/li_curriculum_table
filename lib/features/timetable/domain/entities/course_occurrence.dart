import 'package:flutter/material.dart';

class CourseOccurrence {
  const CourseOccurrence({
    required this.courseName,
    required this.teacher,
    required this.location,
    required this.credit,
    required this.courseType,
    required this.stage,
    required this.start,
    required this.end,
    this.startWeek,
    this.endWeek,
    this.weekText = '',
    required this.color,
  });

  final String courseName;
  final String teacher;
  final String location;
  final String credit;
  final String courseType;
  final String stage;
  final DateTime start;
  final DateTime end;
  final int? startWeek;
  final int? endWeek;
  final String weekText;
  final Color color;
}
