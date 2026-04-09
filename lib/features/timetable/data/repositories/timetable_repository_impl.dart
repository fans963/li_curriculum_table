import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/timetable_crawler_client.dart';
import 'package:li_curriculum_table/features/timetable/data/services/kbtable_week_hint_parser.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_time_text_parser.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/section_range_utils.dart';
import 'package:flutter/foundation.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  TimetableRepositoryImpl(this._client);

  final TimetableCrawlerClient _client;

  @override
  Future<TimetableData> fetchTimetable({
    required String username,
    required String password,
  }) async {
    final result = await _client.loginAndFetchSchedule(
      username: username,
      password: password,
    );

    final rawRows = result.rows
        .map(CourseRow.fromParsed)
        .whereType<CourseRow>()
        .toList(growable: false);
    final weekHints = parseKbtableWeekHints(result.html);
    final rows = rawRows
        .map((row) => _mergeWeekHintsIntoRow(row, weekHints))
        .toList(growable: false);

    return TimetableData(
      rows: rows,
      occurrences: buildCourseOccurrences(rows),
      loginLikelySuccess: result.loginLikelySuccess,
    );
  }

  CourseRow _mergeWeekHintsIntoRow(CourseRow row, List<KbtableWeekHint> hints) {
    final slots = parseCourseTimeSlots(row.timeText);
    if (slots.isEmpty) {
      return row;
    }

    final slotTexts = _slotReg
        .allMatches(row.timeText)
        .map((m) => m.group(0) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (slotTexts.length != slots.length) {
      return row;
    }

    // Identify all hints that belong to this course.
    final courseHints =
        hints.where((h) => h.courseName == row.courseName).toList();

    // Group hints and slots by (weekday, largeSessionStart).
    String keyFor(int weekday, int startSection) {
      final range = getLargeSessionRangeForSection(startSection);
      return '$weekday|${range?.$1 ?? startSection}';
    }

    final hintGroups = <String, List<KbtableWeekHint>>{};
    for (final hint in courseHints) {
      final k = keyFor(hint.weekday, hint.startSection);
      hintGroups.putIfAbsent(k, () => []).add(hint);
    }

    final slotGroups = <String, List<int>>{};
    for (var i = 0; i < slots.length; i++) {
      final k = keyFor(slots[i].weekday, slots[i].startSection);
      slotGroups.putIfAbsent(k, () => []).add(i);
    }

    final finalMatchedHints =
        List<List<String>>.generate(slots.length, (_) => []);

    for (final k in slotGroups.keys) {
      final indices = slotGroups[k]!;
      final gHints = hintGroups[k] ?? [];

      if (indices.length == gHints.length && indices.length > 1) {
        // Precise 1-to-1 matching if counts match within a session block.
        for (var j = 0; j < indices.length; j++) {
          finalMatchedHints[indices[j]] = [gHints[j].weekText];
        }
      } else {
        // Fallback to broad overlapping match.
        for (final idx in indices) {
          final slot = slots[idx];
          for (final hint in gHints) {
            final overlapsSize =
                hint.startSection <= slot.endSection &&
                hint.endSection >= slot.startSection;
            if (overlapsSize && !finalMatchedHints[idx].contains(hint.weekText)) {
              finalMatchedHints[idx].add(hint.weekText);
            }
          }
        }
      }
    }

    final mergedParts = <String>[];
    for (var i = 0; i < slots.length; i++) {
      final matched = finalMatchedHints[i];
      if (matched.isEmpty) {
        mergedParts.add(slotTexts[i]);
      } else {
        for (final weekText in matched) {
          mergedParts.add('$weekText ${slotTexts[i]}');
        }
      }
    }

    return CourseRow(
      courseId: row.courseId,
      order: row.order,
      courseName: row.courseName,
      teacher: row.teacher,
      timeText: mergedParts.join(''),
      credit: row.credit,
      location: row.location,
      courseType: row.courseType,
      stage: row.stage,
    );
  }
}

final RegExp _slotReg = RegExp(r'星期[一二三四五六日天]\(\d{2}-\d{2}小节\)');
