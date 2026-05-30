import '../models/exam.dart';

abstract class ExamRepository {
  Future<List<ExamEntity>> getExams({bool forceRefresh = false});
  Future<void> clearCache();
}
