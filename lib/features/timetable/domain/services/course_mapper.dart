import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
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
  final reg = RegExp(r'星期([一二三四五六日天])\((\d{2})-(\d{2})小节\)');
  final dedup = <String>{};
  final result = <CourseOccurrence>[];

  for (final row in rows) {
    final matches = reg.allMatches(row.timeText).toList(growable: false);
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final weekday = _weekdayFromChinese(m.group(1)!);
      final startSection = int.parse(m.group(2)!);
      final endSection = int.parse(m.group(3)!);
      final startClock = startClockOfSection(startSection);
      final endClock = endClockOfSection(endSection);
      if (weekday == null || startClock == null || endClock == null) {
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
          '${row.courseId}|${row.courseName}|$weekday|$startSection|$endSection';
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

int? _weekdayFromChinese(String c) {
  switch (c) {
    case '一':
      return DateTime.monday;
    case '二':
      return DateTime.tuesday;
    case '三':
      return DateTime.wednesday;
    case '四':
      return DateTime.thursday;
    case '五':
      return DateTime.friday;
    case '六':
      return DateTime.saturday;
    case '日':
    case '天':
      return DateTime.sunday;
    default:
      return null;
  }
}
