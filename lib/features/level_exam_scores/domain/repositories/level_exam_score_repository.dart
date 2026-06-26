import '../models/level_exam_score.dart';

abstract class LevelExamScoreRepository {
  Future<List<LevelExamScoreEntity>> getScores({bool forceRefresh = false});
  Future<void> clearCache();
}
