import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';

part 'classroom_state.freezed.dart';

@freezed
abstract class ClassroomState with _$ClassroomState {
  const factory ClassroomState({
    @Default([]) List<Campus> campuses,
    Campus? selectedCampus,
    @Default([]) List<Building> buildings,
    Building? selectedBuilding,
    required DateTime selectedDate,
    @Default([]) List<ClassroomAvailability> results,
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool needsLogin,
    @Default('') String currentTerm,
  }) = _ClassroomState;
}
