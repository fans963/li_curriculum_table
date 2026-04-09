import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentialsLocalDataSource {
  SecureCredentialsLocalDataSource(this._storage);

  static const String _usernameKey = 'timetable.credentials.username';
  static const String _passwordKey = 'timetable.credentials.password';

  final FlutterSecureStorage _storage;

  Future<LoginCredentials?> readCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    if (username == null ||
        username.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return LoginCredentials(username: username, password: password);
  }

  Future<void> saveCredentials(LoginCredentials credentials) async {
    await _storage.write(key: _usernameKey, value: credentials.username.trim());
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}
