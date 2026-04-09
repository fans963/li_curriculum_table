import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';

abstract class CredentialsRepository {
  Future<LoginCredentials?> readCredentials();

  Future<void> saveCredentials(LoginCredentials credentials);

  Future<void> clearCredentials();
}
