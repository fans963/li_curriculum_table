import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import '../../domain/models/grade.dart';

class GradeLocalDataSource {
  final SecureStorageStore _store;

  GradeLocalDataSource(this._store);

  Future<T> _runTask<T>(FutureOr<T> Function() action) async {
    if (kIsWeb) {
      return action();
    } else {
      return await Isolate.run(action);
    }
  }

  static const String _gradesKey = 'grades.cache.list';

  Future<List<GradeEntity>?> readGrades() async {
    final data = await _store.readAll([_gradesKey]);
    final jsonStr = data[_gradesKey];
    if (jsonStr == null) return null;
    
    return await _runTask(() {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => GradeEntity.fromJson(e)).toList();
    });
  }

  Future<void> saveGrades(List<GradeEntity> grades) async {
    final jsonStr = await _runTask(() {
      return jsonEncode(grades.map((e) => e.toJson()).toList());
    });
    await _store.writeAll({_gradesKey: jsonStr});
  }

  Future<void> clear() async {
    await _store.deleteAll([_gradesKey]);
  }
}
