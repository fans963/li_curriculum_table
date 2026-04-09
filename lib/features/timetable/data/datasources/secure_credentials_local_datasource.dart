import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class SecureCredentialsLocalDataSource {
  SecureCredentialsLocalDataSource(this._store);

  static const String _usernameKey = 'timetable.credentials.username';
  static const String _passwordKey = 'timetable.credentials.password';

  final SecureStorageStore _store;

  Future<LoginCredentials?> readCredentials() async {
    final values = await _store.readAll([_usernameKey, _passwordKey]);
    final username = values[_usernameKey];
    final password = values[_passwordKey];

    if (username == null ||
        username.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return LoginCredentials(username: username, password: password);
  }

  Future<void> saveCredentials(LoginCredentials credentials) async {
    await _store.writeAll({
      _usernameKey: credentials.username.trim(),
      _passwordKey: credentials.password,
    });
  }

  Future<void> clearCredentials() async {
    await _store.deleteAll([_usernameKey, _passwordKey]);
  }
}
