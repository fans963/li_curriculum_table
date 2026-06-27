import 'package:li_curriculum_table/core/rust/api/level_exam_score.dart'
    as rust_api;
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;
import '../../domain/models/level_exam_score.dart';

class LevelExamScoreRemoteDataSource {
  Future<List<LevelExamScoreEntity>> getScores({
    required String username,
    required String password,
  }) async {
    final List<rust_model.LevelExamScore> rustScores = await rust_api
        .getLevelExamScores(username: username, password: password);

    return rustScores
        .map(
          (s) => LevelExamScoreEntity(
            courseName: s.courseName,
            writtenScore: s.writtenScore,
            practicalScore: s.practicalScore,
            totalScore: s.totalScore,
            writtenGrade: s.writtenGrade,
            practicalGrade: s.practicalGrade,
            totalGrade: s.totalGrade,
            examDate: s.examDate,
          ),
        )
        .toList();
  }
}
