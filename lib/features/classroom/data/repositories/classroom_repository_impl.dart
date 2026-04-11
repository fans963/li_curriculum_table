import 'package:li_curriculum_table/features/classroom/data/datasources/classroom_remote_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/secure_classroom_local_datasource.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_schedule.dart';
import 'package:li_curriculum_table/features/classroom/domain/repositories/classroom_repository.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  final ClassroomRemoteDataSource _remoteDataSource;
  final ClassroomLocalDataSource _localDataSource;

  ClassroomRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<(List<CampusEntity>, String)> getCampuses({
    String? username,
    String? password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localDataSource.readCampuses();
      if (cached != null) {
        return cached;
      }
    }

    final result = await _remoteDataSource.getCampuses(
      username: username,
      password: password,
    );
    final (campuses, term) = result;
    await _localDataSource.saveCampuses(campuses, term);
    return result;
  }

  @override
  Future<List<BuildingEntity>> getBuildings(
    String campusId, {
    String? username,
    String? password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localDataSource.readBuildings(campusId);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final buildings = await _remoteDataSource.getBuildings(
      campusId,
      username: username,
      password: password,
    );
    await _localDataSource.saveBuildings(campusId, buildings);
    return buildings;
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
    bool forceRefresh = false,
  }) async {
    List<ClassroomScheduleEntity>? schedule;

    if (!forceRefresh) {
      schedule = await _localDataSource.readBuildingSchedule(
        campusId: campusId,
        buildingId: buildingId,
      );
    }

    if (schedule == null || schedule.isEmpty) {
      schedule = await _remoteDataSource.getBuildingSchedule(
        campusId: campusId,
        buildingId: buildingId,
        term: term,
        username: username,
        password: password,
      );

      await _localDataSource.saveBuildingSchedule(
        campusId: campusId,
        buildingId: buildingId,
        schedule: schedule,
      );
    }

    // Filter by week and weekday locally
    final List<ClassroomAvailabilityEntity> results = [];
    for (final s in schedule) {
      final availability = List.filled(5, true);
      for (final slot in s.occupiedSlots) {
        if (slot.weekday == weekday &&
            week >= slot.startWeek &&
            week <= slot.endWeek) {
          if (slot.slotIndex >= 0 && slot.slotIndex < 5) {
            availability[slot.slotIndex] = false;
          }
        }
      }
      results.add(ClassroomAvailabilityEntity(
        classroomName: s.classroomName,
        availability: availability,
        hasNoClassesThisTerm: s.occupiedSlots.isEmpty,
      ));

    }

    // Sort by name for consistency
    results.sort((a, b) => a.classroomName.compareTo(b.classroomName));

    return results;
  }
}

