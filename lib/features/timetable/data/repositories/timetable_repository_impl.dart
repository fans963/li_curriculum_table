import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/timetable_crawler_client.dart';
import 'package:li_curriculum_table/features/timetable/data/services/kbtable_week_hint_parser.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_time_text_parser.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';
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
    if (kDebugMode) {
      final rowsWithWeek = rows.where((e) => e.timeText.contains('周')).length;
      debugPrint(
        '[WEEK_HINT] parsedHints=${weekHints.length} rowsWithWeek=$rowsWithWeek/${rows.length}',
      );
    }

    return TimetableData(
      rows: rows,
      occurrences: buildCourseOccurrences(rows),
      captchaBytes: result.captchaBytes,
      verifyCode: result.verifyCode,
      loginLikelySuccess: result.loginLikelySuccess,
      networkLogs: result.networkLogs,
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

    final mergedParts = <String>[];
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final matchedWeekTexts = <String>[];
      for (final hint in hints) {
        final sameCourseAndWeekday =
            hint.courseName == row.courseName && hint.weekday == slot.weekday;
        if (!sameCourseAndWeekday) {
          continue;
        }

        // Use overlapping ranges instead of strict equality to tolerate
        // dataList anomalies like 01-03 vs 02-03 for the same kbtable block.
        final overlapsSection =
            hint.startSection <= slot.endSection &&
            hint.endSection >= slot.startSection;
        if (!overlapsSection) {
          continue;
        }
        if (!matchedWeekTexts.contains(hint.weekText)) {
          matchedWeekTexts.add(hint.weekText);
        }
      }

      final slotText = slotTexts[i];
      if (matchedWeekTexts.isEmpty) {
        mergedParts.add(slotText);
      } else {
        for (final weekText in matchedWeekTexts) {
          mergedParts.add('$weekText $slotText');
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
