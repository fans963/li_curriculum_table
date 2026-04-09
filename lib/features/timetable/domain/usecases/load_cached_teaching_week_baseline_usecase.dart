import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/teaching_week_baseline_repository.dart';

class LoadCachedTeachingWeekBaselineUseCase {
  LoadCachedTeachingWeekBaselineUseCase(this._repository);

  final TeachingWeekBaselineRepository _repository;

  Future<TeachingWeekBaseline?> call() {
    return _repository.readBaseline();
  }
}
