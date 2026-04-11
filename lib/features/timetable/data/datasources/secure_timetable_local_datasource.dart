import 'dart:convert';
import 'dart:isolate';

import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';

class SecureTimetableLocalDataSource {
  SecureTimetableLocalDataSource(this._store);

  static const String _rowsJsonKey = 'timetable.cache.rows_json';
  static const String _cachedAtKey = 'timetable.cache.cached_at';

  final SecureStorageStore _store;

  Future<CachedTimetable?> readCachedTimetable() async {
    final values = await _store.readAll([_rowsJsonKey, _cachedAtKey]);
    final rowsJson = values[_rowsJsonKey];
    final cachedAtValue = values[_cachedAtKey];
    if (rowsJson == null || cachedAtValue == null) {
      return null;
    }

    final cachedAt = DateTime.tryParse(cachedAtValue);
    if (cachedAt == null) {
      return null;
    }

    return await Isolate.run(() {
      final decoded = jsonDecode(rowsJson);
      if (decoded is! List) {
        return null;
      }

      final rows = <CourseRow>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          return null;
        }
        final row = CourseRow.fromJson(entry);
        if (row == null) {
          return null;
        }
        rows.add(row);
      }

      return CachedTimetable(rows: rows, cachedAt: cachedAt);
    });
  }

  Future<void> saveCachedTimetable(CachedTimetable cached) async {
    final rowsJson = await Isolate.run(() {
      return jsonEncode(
        cached.rows.map((row) => row.toJson()).toList(growable: false),
      );
    });
    await _store.writeAll({
      _rowsJsonKey: rowsJson,
      _cachedAtKey: cached.cachedAt.toIso8601String(),
    });
  }

  Future<void> clearCachedTimetable() async {
    await _store.deleteAll([_rowsJsonKey, _cachedAtKey]);
  }
}
