import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';

class SecureScheduleEventsLocalDataSource {
  SecureScheduleEventsLocalDataSource(this._store);

  static const String _key = 'timetable.cache.schedule_events_json';

  final SecureStorageStore _store;

  Future<List<ScheduleEvent>> load() async {
    final values = await _store.readAll([_key]);
    final json = values[_key];
    if (json == null) return <ScheduleEvent>[];

    try {
      return await Isolate.run(() {
        final decoded = jsonDecode(json);
        if (decoded is! List) return <ScheduleEvent>[];
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => ScheduleEvent.fromJson(e))
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to decode schedule events: $e');
      return <ScheduleEvent>[];
    }
  }

  Future<void> save(List<ScheduleEvent> events) async {
    final json = await Isolate.run(() {
      return jsonEncode(events.map((e) => e.toJson()).toList(growable: false));
    });
    await _store.writeAll({_key: json});
  }

  Future<void> clear() async {
    await _store.deleteAll([_key]);
  }
}
