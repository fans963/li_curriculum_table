import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_time_text_parser.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/section_time_mapping.dart';
import 'package:flutter/material.dart';

DateTime mondayOfCurrentWeek() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - DateTime.monday));
}

List<CourseOccurrence> buildCourseOccurrences(List<CourseRow> rows) {
  final weekStart = mondayOfCurrentWeek();
  final dedup = <String>{};
  final result = <CourseOccurrence>[];

  for (final row in rows) {
    final slots = parseCourseTimeSlots(row.timeText);
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final weekday = slot.weekday;
      final startSection = slot.startSection;
      final endSection = slot.endSection;
      final startClock = startClockOfSection(startSection);
      final endClock = endClockOfSection(endSection);
      if (startClock == null || endClock == null) {
        continue;
      }

      final day = weekStart.add(Duration(days: weekday - DateTime.monday));
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        startClock.$1,
        startClock.$2,
      );
      final end = DateTime(
        day.year,
        day.month,
        day.day,
        endClock.$1,
        endClock.$2,
      );

      final key =
          '${row.courseId}|${row.courseName}|$weekday|$startSection|$endSection|${slot.startWeek}|${slot.endWeek}|${slot.weekText}';
      if (!dedup.add(key)) {
        continue;
      }

      result.add(
        CourseOccurrence(
          courseName: row.courseName,
          teacher: row.teacher,
          location: _locationAt(row.location, i),
          credit: row.credit,
          courseType: row.courseType,
          stage: row.stage,
          start: start,
          end: end,
          startWeek: slot.startWeek,
          endWeek: slot.endWeek,
          weekText: slot.weekText,
          color: _colorFromCourseId(row.courseId),
        ),
      );
    }
  }

  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}

String _locationAt(String raw, int index) {
  final items = raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
  if (items.isEmpty) {
    return '';
  }
  if (index < items.length) {
    return items[index];
  }
  return items.last;
}

Color _colorFromCourseId(String courseId) {
  const palette = <Color>[
    Color(0xFF00695C),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFF1565C0),
    Color(0xFFAD1457),
    Color(0xFF5D4037),
    Color(0xFF00838F),
    Color(0xFF283593),
    Color(0xFF37474F),
  ];

  var hash = 0;
  for (final code in courseId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}
