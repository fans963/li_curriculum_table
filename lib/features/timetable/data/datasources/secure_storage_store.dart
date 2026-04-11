import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageStore {
  SecureStorageStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<Map<String, String?>> readAll(List<String> keys) async {
    final result = <String, String?>{};
    for (final key in keys) {
      result[key] = await _storage.read(key: key);
    }
    return result;
  }

  Future<void> writeAll(Map<String, String> values) async {
    for (final entry in values.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }

  Future<void> deleteAllExcept(List<String> preservedKeys) async {
    final allEntries = await _storage.readAll();
    for (final key in allEntries.keys) {
      if (!preservedKeys.contains(key)) {
        await _storage.delete(key: key);
      }
    }
  }
}
