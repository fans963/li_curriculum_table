import 'package:li_curriculum_table/features/timetable/data/datasources/secure_credentials_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';

class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl(this._localDataSource);

  final SecureCredentialsLocalDataSource _localDataSource;

  @override
  Future<LoginCredentials?> loadCredentials() {
    return _localDataSource.readCredentials();
  }

  @override
  Future<void> cacheCredentials(LoginCredentials credentials) {
    return _localDataSource.saveCredentials(credentials);
  }

  @override
  Future<void> clearCredentials() {
    return _localDataSource.clearCredentials();
  }
}
