import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';

class CacheTimetableUseCase {
  CacheTimetableUseCase(this._repository);

  final TimetableCacheRepository _repository;

  Future<void> call(List<CourseRow> rows) {
    return _repository.saveCachedTimetable(
      CachedTimetable(rows: rows, cachedAt: DateTime.now()),
    );
  }
}
