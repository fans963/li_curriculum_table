import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';

class ClearCachedCredentialsUseCase {
  ClearCachedCredentialsUseCase(this._repository);

  final CredentialsRepository _repository;

  Future<void> call() {
    return _repository.clearCredentials();
  }
}
