import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/teaching_week_baseline_repository.dart';

class CacheTeachingWeekBaselineUseCase {
  CacheTeachingWeekBaselineUseCase(this._repository);

  final TeachingWeekBaselineRepository _repository;

  Future<void> call(TeachingWeekBaseline baseline) {
    if (!baseline.isValid) {
      return _repository.clearBaseline();
    }
    return _repository.saveBaseline(baseline);
  }
}
