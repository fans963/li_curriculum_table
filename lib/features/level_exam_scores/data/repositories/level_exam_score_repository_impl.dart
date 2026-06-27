import 'package:li_curriculum_table/features/timetable/data/datasources/secure_credentials_local_datasource.dart';
import '../datasources/level_exam_score_local_datasource.dart';
import '../datasources/level_exam_score_remote_datasource.dart';
import '../../domain/models/level_exam_score.dart';
import '../../domain/repositories/level_exam_score_repository.dart';

class LevelExamScoreRepositoryImpl implements LevelExamScoreRepository {
  final LevelExamScoreRemoteDataSource _remoteDataSource;
  final LevelExamScoreLocalDataSource _localDataSource;
  final SecureCredentialsLocalDataSource _credentialsDataSource;

  LevelExamScoreRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._credentialsDataSource,
  );

  @override
  Future<List<LevelExamScoreEntity>> getScores({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localDataSource.readScores();
      if (cached != null) return cached;
    }

    final credentials = await _credentialsDataSource.readCredentials();
    if (credentials == null || credentials.isEmpty) {
      throw Exception('未登录，无法获取等级考试成绩');
    }

    final scores = await _remoteDataSource.getScores(
      username: credentials.username,
      password: credentials.password,
    );

    await _localDataSource.saveScores(scores);
    return scores;
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clear();
  }
}
