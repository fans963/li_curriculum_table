import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';

class ClassroomState {
  final List<CampusEntity> campuses;
  final CampusEntity? selectedCampus;
  final List<BuildingEntity> buildings;
  final BuildingEntity? selectedBuilding;
  final DateTime selectedDate;
  final List<ClassroomAvailabilityEntity> results;
  final bool isLoading;
  final String? error;
  final bool needsLogin;

  ClassroomState({
    this.campuses = const [],
    this.selectedCampus,
    this.buildings = const [],
    this.selectedBuilding,
    required this.selectedDate,
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.needsLogin = false,
  });

  ClassroomState copyWith({
    List<CampusEntity>? campuses,
    CampusEntity? selectedCampus,
    List<BuildingEntity>? buildings,
    BuildingEntity? selectedBuilding,
    DateTime? selectedDate,
    List<ClassroomAvailabilityEntity>? results,
    bool? isLoading,
    String? error,
    bool? needsLogin,
  }) {
    return ClassroomState(
      campuses: campuses ?? this.campuses,
      selectedCampus: selectedCampus ?? this.selectedCampus,
      buildings: buildings ?? this.buildings,
      selectedBuilding: selectedBuilding ?? this.selectedBuilding,
      selectedDate: selectedDate ?? this.selectedDate,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      needsLogin: needsLogin ?? this.needsLogin,
    );
  }
}
