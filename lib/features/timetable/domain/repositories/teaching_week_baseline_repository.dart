import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';

abstract class TeachingWeekBaselineRepository {
  Future<TeachingWeekBaseline?> readBaseline();

  Future<void> saveBaseline(TeachingWeekBaseline baseline);

  Future<void> clearBaseline();
}
