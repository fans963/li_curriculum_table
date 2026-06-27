import 'package:flutter/foundation.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';
import '../../domain/models/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../../timetable/data/datasources/secure_credentials_local_datasource.dart';

class ExamRepositoryImpl implements ExamRepository {
  final ExamRemoteDataSource _remoteDataSource;
  final ExamLocalDataSource _localDataSource;
  final SecureCredentialsLocalDataSource _credentialsDataSource;

  ExamRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._credentialsDataSource,
  );

  @override
  Future<List<ExamEntity>> getExams({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('[ExamRepo] getExams(forceRefresh=$forceRefresh)');
    }

    if (!forceRefresh) {
      final cached = await _localDataSource.readExams();
      if (cached != null) {
        if (kDebugMode) {
          print('[ExamRepo] Returning ${cached.length} cached exams');
        }
        return cached;
      }
      if (kDebugMode) {
        print('[ExamRepo] No cache found, fetching from remote');
      }
    }

    final credentials = await _credentialsDataSource.readCredentials();
    if (credentials == null || credentials.isEmpty) {
      if (kDebugMode) {
        print('[ExamRepo] No credentials found');
      }
      throw Exception('未登录，无法获取考试安排');
    }

    if (kDebugMode) {
      print('[ExamRepo] Fetching exams for user: ${credentials.username}');
    }

    final exams = await _remoteDataSource.getExams(
      username: credentials.username,
      password: credentials.password,
    );

    if (kDebugMode) {
      print('[ExamRepo] Fetched ${exams.length} exams, saving to cache');
    }

    await _localDataSource.saveExams(exams);
    return exams;
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clear();
  }
}
