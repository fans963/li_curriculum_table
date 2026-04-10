import 'dart:convert';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_schedule.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';

class ClassroomLocalDataSource {
  final SecureStorageStore _store;

  ClassroomLocalDataSource(this._store);

  static const String _campusesKey = 'classroom.cache.campuses';

  String _buildingsKey(String campusId) => 'classroom.cache.buildings.$campusId';

  String _availabilityKey(String campusId, String buildingId, int week, int weekday) =>
      'classroom.cache.availability.$campusId.$buildingId.$week.$weekday';

  String _bulkScheduleKey(String campusId, String buildingId) =>
      'classroom.cache.bulk_schedule.$campusId.$buildingId';

  Future<List<CampusEntity>?> readCampuses() async {
    final data = await _store.readAll([_campusesKey]);
    final jsonStr = data[_campusesKey];
    if (jsonStr == null) return null;
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => CampusEntity.fromJson(e)).toList();
  }

  Future<void> saveCampuses(List<CampusEntity> campuses) async {
    final jsonStr = jsonEncode(campuses.map((e) => e.toJson()).toList());
    await _store.writeAll({_campusesKey: jsonStr});
  }

  Future<List<BuildingEntity>?> readBuildings(String campusId) async {
    final key = _buildingsKey(campusId);
    final data = await _store.readAll([key]);
    final jsonStr = data[key];
    if (jsonStr == null) return null;
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => BuildingEntity.fromJson(e)).toList();
  }

  Future<void> saveBuildings(String campusId, List<BuildingEntity> buildings) async {
    final key = _buildingsKey(campusId);
    final jsonStr = jsonEncode(buildings.map((e) => e.toJson()).toList());
    await _store.writeAll({key: jsonStr});
  }

  Future<List<ClassroomAvailabilityEntity>?> readAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
  }) async {
    final key = _availabilityKey(campusId, buildingId, week, weekday);
    final data = await _store.readAll([key]);
    final jsonStr = data[key];
    if (jsonStr == null) return null;
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => ClassroomAvailabilityEntity.fromJson(e)).toList();
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
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => ClassroomScheduleEntity.fromJson(e)).toList();
  }

  Future<void> saveBuildingSchedule({
    required String campusId,
    required String buildingId,
    required List<ClassroomScheduleEntity> schedule,
  }) async {
    final key = _bulkScheduleKey(campusId, buildingId);
    final jsonStr = jsonEncode(schedule.map((e) => e.toJson()).toList());
    await _store.writeAll({key: jsonStr});
  }
}
