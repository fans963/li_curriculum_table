import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';

abstract class TimetableCacheRepository {
  Future<CachedTimetable?> readCachedTimetable();

  Future<void> saveCachedTimetable(CachedTimetable cached);

  Future<void> clearCachedTimetable();
}
