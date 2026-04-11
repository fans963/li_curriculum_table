import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';

abstract class TimetableCacheRepository {
  Future<CachedTimetable?> loadTimetable();

  Future<void> cacheTimetable(CachedTimetable cached);

  Future<void> clearCachedTimetable();
}
