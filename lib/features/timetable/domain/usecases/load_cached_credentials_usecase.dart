import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';

class LoadCachedCredentialsUseCase {
  LoadCachedCredentialsUseCase(this._repository);

  final CredentialsRepository _repository;

  Future<LoginCredentials?> call() {
    return _repository.readCredentials();
  }
}
