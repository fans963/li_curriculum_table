import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';

abstract class ClassroomRepository {
  Future<List<CampusEntity>> getCampuses({
    String? username,
    String? password,
    bool forceRefresh = false,
  });

  Future<List<BuildingEntity>> getBuildings(
    String campusId, {
    String? username,
    String? password,
    bool forceRefresh = false,
  });

  Future<List<ClassroomAvailabilityEntity>> getClassroomAvailability({
    required String campusId,
    required String buildingId,
    required int week,
    required int weekday,
    String? username,
    String? password,
    bool forceRefresh = false,
  });
}
