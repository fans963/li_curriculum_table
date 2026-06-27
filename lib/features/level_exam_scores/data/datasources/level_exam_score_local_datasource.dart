import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import '../../domain/models/level_exam_score.dart';

class LevelExamScoreLocalDataSource {
  final SecureStorageStore _store;

  LevelExamScoreLocalDataSource(this._store);

  Future<T> _runTask<T>(FutureOr<T> Function() action) async {
    if (kIsWeb) {
      return action();
    } else {
      return await Isolate.run(action);
    }
  }

  static const String _key = 'level_exam_scores.cache.list';

  Future<List<LevelExamScoreEntity>?> readScores() async {
    final data = await _store.readAll([_key]);
    final jsonStr = data[_key];
    if (jsonStr == null) return null;

    return await _runTask(() {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => LevelExamScoreEntity.fromJson(e)).toList();
    });
  }

  Future<void> saveScores(List<LevelExamScoreEntity> scores) async {
    final jsonStr = await _runTask(() {
      return jsonEncode(scores.map((e) => e.toJson()).toList());
    });
    await _store.writeAll({_key: jsonStr});
  }

  Future<void> clear() async {
    await _store.deleteAll([_key]);
  }
}
