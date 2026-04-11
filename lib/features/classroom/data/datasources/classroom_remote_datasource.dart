import 'package:li_curriculum_table/core/rust/api/classroom.dart' as rust;
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_schedule.dart';

abstract class ClassroomRemoteDataSource {
  Future<(List<CampusEntity>, String)> getCampuses({String? username, String? password});
  Future<List<BuildingEntity>> getBuildings(String campusId, {String? username, String? password});
  Future<List<ClassroomAvailabilityEntity>> getClassroomAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
    required String term,
    String? username,
    String? password,
  });
  Future<List<ClassroomScheduleEntity>> getBuildingSchedule({
    required String campusId,
    required String buildingId,
    required String term,
    String? username,
    String? password,
  });

}

class ClassroomRemoteDataSourceImpl implements ClassroomRemoteDataSource {
  @override
  Future<(List<CampusEntity>, String)> getCampuses({String? username, String? password}) async {
    final data = await rust.getCampuses(username: username, password: password);
    final campuses = data.campuses.map((c) => CampusEntity(id: c.id, name: c.name)).toList();
    return (campuses, data.currentTerm);
  }

  @override
  Future<List<BuildingEntity>> getBuildings(String campusId, {String? username, String? password}) async {
    final buildings = await rust.getBuildings(campusId: campusId, username: username, password: password);
    return buildings.map((b) => BuildingEntity(id: b.id, name: b.name)).toList();
  }

  @override
  Future<List<ClassroomAvailabilityEntity>> getClassroomAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
    required String term,
    String? username,
    String? password,
  }) async {
    final results = await rust.getClassroomAvailability(
      campusId: campusId,
      buildingId: buildingId,
      week: week,
      weekday: weekday,
      term: term,
      username: username,
      password: password,
    );
    return results
        .map((r) => ClassroomAvailabilityEntity(
              classroomName: r.classroomName,
              availability: r.availability,
            ))
        .toList();
  }


  @override
  Future<List<ClassroomScheduleEntity>> getBuildingSchedule({
    required String campusId,
    required String buildingId,
    required String term,
    String? username,
    String? password,
  }) async {
    final results = await rust.getBuildingSchedule(
      campusId: campusId,
      buildingId: buildingId,
      term: term,
      username: username,
      password: password,
    );
    return results
        .map((s) => ClassroomScheduleEntity(
              classroomName: s.classroomName,
              occupiedSlots: s.occupiedSlots
                  .map((o) => OccupiedSlotEntity(
                        startWeek: o.startWeek,
                        endWeek: o.endWeek,
                        weekday: o.weekday,
                        slotIndex: o.slotIndex,
                      ))
                  .toList(),
            ))
        .toList();
  }

}
