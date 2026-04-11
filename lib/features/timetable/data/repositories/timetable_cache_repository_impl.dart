import 'package:li_curriculum_table/features/timetable/data/datasources/secure_timetable_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';

class TimetableCacheRepositoryImpl implements TimetableCacheRepository {
  TimetableCacheRepositoryImpl(this._localDataSource);

  final SecureTimetableLocalDataSource _localDataSource;

  @override
  Future<CachedTimetable?> loadTimetable() {
    return _localDataSource.readCachedTimetable();
  }

  @override
  Future<void> cacheTimetable(CachedTimetable cached) {
    return _localDataSource.saveCachedTimetable(cached);
  }

  @override
  Future<void> clearCachedTimetable() {
    return _localDataSource.clearCachedTimetable();
  }
}
