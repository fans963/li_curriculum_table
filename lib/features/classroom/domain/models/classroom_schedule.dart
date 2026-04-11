import 'package:freezed_annotation/freezed_annotation.dart';

part 'classroom_schedule.freezed.dart';
part 'classroom_schedule.g.dart';

@freezed
abstract class OccupiedSlot with _$OccupiedSlot {
  const factory OccupiedSlot({
    required int startWeek,
    required int endWeek,
    required int weekday,
    required int slotIndex,
  }) = _OccupiedSlot;

  factory OccupiedSlot.fromJson(Map<String, dynamic> json) =>
      _$OccupiedSlotFromJson(json);
}

@freezed
abstract class ClassroomSchedule with _$ClassroomSchedule {
  const factory ClassroomSchedule({
    required String classroomName,
    required List<OccupiedSlot> occupiedSlots,
  }) = _ClassroomSchedule;

  factory ClassroomSchedule.fromJson(Map<String, dynamic> json) =>
      _$ClassroomScheduleFromJson(json);
}
