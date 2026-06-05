import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageException implements Exception {
  final String message;
  final Object? cause;
  SecureStorageException(this.message, [this.cause]);

  @override
  String toString() => 'SecureStorageException: $message';
}

class SecureStorageStore {
  SecureStorageStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<Map<String, String?>> readAll(List<String> keys) async {
    try {
      final result = <String, String?>{};
      for (final key in keys) {
        result[key] = await _storage.read(key: key);
      }
      return result;
    } catch (e) {
      debugPrint('SecureStorageStore.readAll error: $e');
      throw SecureStorageException('Failed to read from secure storage', e);
    }
  }

  Future<void> writeAll(Map<String, String> values) async {
    try {
      for (final entry in values.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }
    } catch (e) {
      debugPrint('SecureStorageStore.writeAll error: $e');
      throw SecureStorageException('Failed to write to secure storage', e);
    }
  }

  Future<void> deleteAll(List<String> keys) async {
    try {
      for (final key in keys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      debugPrint('SecureStorageStore.deleteAll error: $e');
      throw SecureStorageException('Failed to delete from secure storage', e);
    }
  }

  Future<void> deleteAllExcept(List<String> preservedKeys) async {
    try {
      final preservedSet = preservedKeys.toSet();
      final allEntries = await _storage.readAll();
      for (final key in allEntries.keys) {
        if (!preservedSet.contains(key)) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      debugPrint('SecureStorageStore.deleteAllExcept error: $e');
      throw SecureStorageException('Failed to clean secure storage', e);
    }
  }
}
