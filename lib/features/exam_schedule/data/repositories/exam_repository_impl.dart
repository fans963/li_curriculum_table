import 'package:li_curriculum_table/core/services/app_logger.dart';
import '../datasources/exam_local_datasource.dart';
import '../datasources/exam_remote_datasource.dart';
import '../../domain/models/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../../timetable/data/datasources/secure_credentials_local_datasource.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart' as rust_api;

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
    AppLogger.instance.info(
      'getExams(forceRefresh=$forceRefresh)',
      tag: 'ExamRepo',
    );

    if (!forceRefresh) {
      final cached = await _localDataSource.readExams();
      if (cached != null) {
        AppLogger.instance.info(
          'Returning ${cached.length} cached exams',
          tag: 'ExamRepo',
        );
        return cached;
      }
      AppLogger.instance.info(
        'No cache found, fetching from remote',
        tag: 'ExamRepo',
      );
    }

    final credentials = await _credentialsDataSource.readCredentials();
    if ((credentials == null || credentials.isEmpty) &&
        !await rust_api.checkSessionValid()) {
      AppLogger.instance.info('No credentials found', tag: 'ExamRepo');
      throw Exception('未登录，无法获取考试安排');
    }

    AppLogger.instance.info(
      'Fetching exams for user: ${credentials?.username ?? 'QR session'}',
      tag: 'ExamRepo',
    );

    final exams = await _remoteDataSource.getExams(
      username: credentials?.username ?? '',
      password: credentials?.password ?? '',
    );

    AppLogger.instance.info(
      'Fetched ${exams.length} exams, saving to cache',
      tag: 'ExamRepo',
    );

    await _localDataSource.saveExams(exams);
    return exams;
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clear();
  }
}
