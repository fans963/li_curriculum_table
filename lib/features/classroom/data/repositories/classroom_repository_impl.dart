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
  Future<List<CampusEntity>> getCampuses({
    String? username,
    String? password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _localDataSource.readCampuses();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final campuses = await _remoteDataSource.getCampuses(
      username: username,
      password: password,
    );
    await _localDataSource.saveCampuses(campuses);
    return campuses;
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
      final term = _getCurrentTerm();
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

  String _getCurrentTerm() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (month >= 2 && month <= 7) {
      // Spring Semester: (Year-1)-Year-2
      return '${year - 1}-$year-2';
    } else if (month >= 8) {
      // Autumn Semester: Year-(Year+1)-1
      return '$year-${year + 1}-1';
    } else {
      // January: (Year-1)-Year-1
      return '${year - 1}-$year-1';
    }
  }
}

