import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import '../../domain/models/exam.dart';

class ExamLocalDataSource {
  final SecureStorageStore _store;

  ExamLocalDataSource(this._store);

  Future<T> _runTask<T>(FutureOr<T> Function() action) async {
    if (kIsWeb) {
      return action();
    } else {
      return await Isolate.run(action);
    }
  }

  static const String _examsKey = 'exams.cache.list';

  Future<List<ExamEntity>?> readExams() async {
    final data = await _store.readAll([_examsKey]);
    final jsonStr = data[_examsKey];
    if (jsonStr == null) return null;

    return await _runTask(() {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ExamEntity.fromJson(e)).toList();
    });
  }

  Future<void> saveExams(List<ExamEntity> exams) async {
    final jsonStr = await _runTask(() {
      return jsonEncode(exams.map((e) => e.toJson()).toList());
    });
    await _store.writeAll({_examsKey: jsonStr});
  }

  Future<void> clear() async {
    await _store.deleteAll([_examsKey]);
  }
}
