import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class CacheBackupService {
  CacheBackupService(this._store);

  final SecureStorageStore _store;

  static const _backupVersion = 1;

  /// Export all cache data to a JSON file and share / save it.
  /// Returns the file path on success, null if the user cancelled the save dialog.
  Future<String?> exportAndShare({bool includeCredentials = false}) async {
    try {
      final entries = await _store.readAllEntries();

      if (!includeCredentials) {
        entries.remove('timetable.credentials.username');
        entries.remove('timetable.credentials.password');
      }

      final backup = {
        'version': _backupVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'entries': entries,
      };

      final jsonStr = await Isolate.run(() => jsonEncode(backup));

      // On platforms that support file sharing (mobile, macOS, Windows),
      // write to a temp file and share. Otherwise fall back to a save dialog.
      if (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/curriculum_table_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await file.writeAsString(jsonStr);

        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
        );

        return file.path;
      } else {
        // Linux & other desktop platforms: prompt user to choose save location.
        final saveLocation = await getSaveLocation(
          suggestedName:
              'curriculum_table_backup_${DateTime.now().millisecondsSinceEpoch}.json',
          acceptedTypeGroups: [
            const XTypeGroup(
              label: 'JSON',
              extensions: ['json'],
              mimeTypes: ['application/json'],
            ),
          ],
        );
        if (saveLocation == null) return null; // user cancelled

        final file = File(saveLocation.path);
        await file.writeAsString(jsonStr);
        return saveLocation.path;
      }
    } catch (e) {
      debugPrint('CacheBackupService.exportAndShare error: $e');
      rethrow;
    }
  }

  /// Pick a backup JSON file and import its entries.
  /// Returns the number of entries imported, or null if cancelled.
  Future<int?> importFromFile() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (file == null) return null;

      final jsonStr = await File(file.path).readAsString();
      final backup = await Isolate.run(
        () => jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      final version = backup['version'] as int?;
      if (version == null || version > _backupVersion) {
        throw const FormatException('不支持的备份文件版本');
      }

      final entries = Map<String, String>.from(backup['entries'] as Map);
      if (entries.isEmpty) return 0;

      await _store.importAll(entries);
      return entries.length;
    } catch (e) {
      debugPrint('CacheBackupService.importFromFile error: $e');
      rethrow;
    }
  }
}
