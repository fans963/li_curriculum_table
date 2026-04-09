import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';

class CacheCredentialsUseCase {
  CacheCredentialsUseCase(this._repository);

  final CredentialsRepository _repository;

  Future<void> call(LoginCredentials credentials) {
    if (credentials.isEmpty) {
      return _repository.clearCredentials();
    }
    return _repository.saveCredentials(credentials);
  }
}
