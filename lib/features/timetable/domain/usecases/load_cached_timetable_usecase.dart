import 'dart:typed_data';

import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';

class LoadCachedTimetableUseCase {
  LoadCachedTimetableUseCase(this._repository);

  final TimetableCacheRepository _repository;

  Future<TimetableData?> call() async {
    final cached = await _repository.readCachedTimetable();
    if (cached == null) {
      return null;
    }

    final rows = cached.rows;
    return TimetableData(
      rows: rows,
      occurrences: buildCourseOccurrences(rows),
      captchaBytes: Uint8List(0),
      verifyCode: '',
      loginLikelySuccess: true,
      networkLogs: const ['已加载本地缓存课表。'],
    );
  }
}
