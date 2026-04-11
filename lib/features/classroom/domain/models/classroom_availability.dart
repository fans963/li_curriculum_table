import 'package:freezed_annotation/freezed_annotation.dart';

part 'classroom_availability.freezed.dart';
part 'classroom_availability.g.dart';

@freezed
abstract class ClassroomAvailability with _$ClassroomAvailability {
  const factory ClassroomAvailability({
    required String classroomName,
    required List<bool> availability, // List of 5 bools for the sessions
    @Default(false) bool hasNoClassesThisTerm,
  }) = _ClassroomAvailability;

  const ClassroomAvailability._();

  factory ClassroomAvailability.fromJson(Map<String, dynamic> json) =>
      _$ClassroomAvailabilityFromJson(json);

  bool isFreeInSession(int sessionIndex) {
    if (sessionIndex < 0 || sessionIndex >= availability.length) return false;
    return availability[sessionIndex];
  }
}
