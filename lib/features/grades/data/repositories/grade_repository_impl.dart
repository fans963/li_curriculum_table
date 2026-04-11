import '../datasources/grade_local_datasource.dart';
import '../datasources/grade_remote_datasource.dart';
import '../../domain/models/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../../../timetable/data/datasources/secure_credentials_local_datasource.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource _remoteDataSource;
  final GradeLocalDataSource _localDataSource;
  final SecureCredentialsLocalDataSource _credentialsDataSource;

  GradeRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._credentialsDataSource,
  );

  @override
  Future<List<GradeEntity>> getGrades({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _localDataSource.readGrades();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final credentials = await _credentialsDataSource.readCredentials();
    if (credentials == null || credentials.isEmpty) {
      throw Exception('未登录，无法获取成绩');
    }

    final grades = await _remoteDataSource.getGrades(
      username: credentials.username,
      password: credentials.password,
    );

    await _localDataSource.saveGrades(grades);
    return grades;
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clear();
  }
}
