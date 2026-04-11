import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';

abstract class CredentialsRepository {
  Future<LoginCredentials?> loadCredentials();

  Future<void> cacheCredentials(LoginCredentials credentials);

  Future<void> clearCredentials();
}
