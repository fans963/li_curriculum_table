import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';

class ClearCachedTimetableUseCase {
  ClearCachedTimetableUseCase(this._repository);

  final TimetableCacheRepository _repository;

  Future<void> call() {
    return _repository.clearCachedTimetable();
  }
}
