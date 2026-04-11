import '../models/grade.dart';

abstract class GradeRepository {
  Future<List<GradeEntity>> getGrades({bool forceRefresh = false});
  Future<void> clearCache();
}
