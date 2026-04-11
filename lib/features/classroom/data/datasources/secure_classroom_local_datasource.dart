import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_schedule.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class ClassroomLocalDataSource {
  final SecureStorageStore _store;

  ClassroomLocalDataSource(this._store);

  Future<T> _runTask<T>(FutureOr<T> Function() action) async {
    if (kIsWeb) {
      return action();
    } else {
      return await Isolate.run(action);
    }
  }

  static const String _campusesKey = 'classroom.cache.campuses';
  static const String _lastCampusKey = 'classroom.cache.last_campus_id';
  static const String _lastBuildingKey = 'classroom.cache.last_building_id';

  String _buildingsKey(String campusId) => 'classroom.cache.buildings.$campusId';

  String _availabilityKey(String campusId, String buildingId, int week, int weekday) =>
      'classroom.cache.availability.$campusId.$buildingId.$week.$weekday';

  String _bulkScheduleKey(String campusId, String buildingId) =>
      'classroom.cache.bulk_schedule.$campusId.$buildingId';

  Future<(List<CampusEntity>, String)?> readCampuses() async {
    try {
      final data = await _store.readAll([_campusesKey]);
      final jsonStr = data[_campusesKey];
      if (jsonStr == null) return null;
      
      return await _runTask(() {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is! Map<String, dynamic>) return null;
        
        final List<dynamic>? campusesRaw = decoded['campuses'];
        final String? term = decoded['currentTerm'];
        
        if (campusesRaw == null || term == null) return null;
        
        final campuses = campusesRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => CampusEntity.fromJson(e))
            .toList();
        return (campuses, term);
      });
    } catch (e) {
      return null;
    }
  }

  Future<void> saveCampuses(List<CampusEntity> campuses, String currentTerm) async {
    final jsonStr = await _runTask(() {
      final payload = {
        'campuses': campuses.map((e) => e.toJson()).toList(),
        'currentTerm': currentTerm,
      };
      return jsonEncode(payload);
    });
    await _store.writeAll({_campusesKey: jsonStr});
  }

  Future<List<BuildingEntity>?> readBuildings(String campusId) async {
    try {
      final key = _buildingsKey(campusId);
      final data = await _store.readAll([key]);
      final jsonStr = data[key];
      if (jsonStr == null) return null;
      
      return await _runTask(() {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is! List) return null;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => BuildingEntity.fromJson(e))
            .toList();
      });
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBuildings(String campusId, List<BuildingEntity> buildings) async {
    final key = _buildingsKey(campusId);
    final jsonStr = await _runTask(() {
      return jsonEncode(buildings.map((e) => e.toJson()).toList());
    });
    await _store.writeAll({key: jsonStr});
  }

  Future<List<ClassroomAvailabilityEntity>?> readAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
  }) async {
    try {
      final key = _availabilityKey(campusId, buildingId, week, weekday);
      final data = await _store.readAll([key]);
      final jsonStr = data[key];
      if (jsonStr == null) return null;
      
      return await _runTask(() {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is! List) return null;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => ClassroomAvailabilityEntity.fromJson(e))
            .toList();
      });
    } catch (e) {
      return null;
    }
  }

  Future<void> saveAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
    required List<ClassroomAvailabilityEntity> results,
  }) async {
    // This is now handled by the bulk schedule cache in typical flows.
    // In a full implementation, we'd prefix all keys and use a store that supports prefix deletion.
  }

  Future<List<ClassroomScheduleEntity>?> readBuildingSchedule({
    required String campusId,
    required String buildingId,
  }) async {
    final key = _bulkScheduleKey(campusId, buildingId);
    final data = await _store.readAll([key]);
    final jsonStr = data[key];
    if (jsonStr == null) return null;
    
    return await _runTask(() {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => ClassroomScheduleEntity.fromJson(e)).toList();
    });
  }

  Future<void> saveBuildingSchedule({
    required String campusId,
    required String buildingId,
    required List<ClassroomScheduleEntity> schedule,
  }) async {
    final key = _bulkScheduleKey(campusId, buildingId);
    final jsonStr = await _runTask(() {
      return jsonEncode(schedule.map((e) => e.toJson()).toList());
    });
    await _store.writeAll({key: jsonStr});
  }

  Future<void> clearAll() async {
    // This is a bit inefficient without prefix support in SecureStorageStore,
    // but we can at least clear the main entry points we know about.
    // However, the new deleteAllExcept in SecureStorageStore is the preferred way 
    // for a "Clear Everything" feature.
    // For a specific feature clear, we'd need to track all building/availability keys.
    await _store.deleteAll([_campusesKey]);
  }

  Future<void> saveLastCampusId(String id) async {
    await _store.writeAll({_lastCampusKey: id});
  }

  Future<String?> readLastCampusId() async {
    final data = await _store.readAll([_lastCampusKey]);
    return data[_lastCampusKey];
  }

  Future<void> saveLastBuildingId(String id) async {
    await _store.writeAll({_lastBuildingKey: id});
  }

  Future<String?> readLastBuildingId() async {
    final data = await _store.readAll([_lastBuildingKey]);
    return data[_lastBuildingKey];
  }
}
