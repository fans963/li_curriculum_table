import 'package:li_curriculum_table/features/timetable/data/datasources/secure_teaching_week_baseline_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/teaching_week_baseline_repository.dart';

class TeachingWeekBaselineRepositoryImpl
    implements TeachingWeekBaselineRepository {
  TeachingWeekBaselineRepositoryImpl(this._localDataSource);

  final SecureTeachingWeekBaselineLocalDataSource _localDataSource;

  @override
  Future<TeachingWeekBaseline?> loadBaseline() {
    return _localDataSource.readBaseline();
  }

  @override
  Future<void> cacheBaseline(TeachingWeekBaseline baseline) {
    return _localDataSource.saveBaseline(baseline);
  }

  @override
  Future<void> clearBaseline() {
    return _localDataSource.clearBaseline();
  }
}
