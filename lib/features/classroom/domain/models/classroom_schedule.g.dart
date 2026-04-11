// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OccupiedSlot _$OccupiedSlotFromJson(Map<String, dynamic> json) =>
    _OccupiedSlot(
      startWeek: (json['startWeek'] as num).toInt(),
      endWeek: (json['endWeek'] as num).toInt(),
      weekday: (json['weekday'] as num).toInt(),
      slotIndex: (json['slotIndex'] as num).toInt(),
    );

Map<String, dynamic> _$OccupiedSlotToJson(_OccupiedSlot instance) =>
    <String, dynamic>{
      'startWeek': instance.startWeek,
      'endWeek': instance.endWeek,
      'weekday': instance.weekday,
      'slotIndex': instance.slotIndex,
    };

_ClassroomSchedule _$ClassroomScheduleFromJson(Map<String, dynamic> json) =>
    _ClassroomSchedule(
      classroomName: json['classroomName'] as String,
      occupiedSlots: (json['occupiedSlots'] as List<dynamic>)
          .map((e) => OccupiedSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClassroomScheduleToJson(_ClassroomSchedule instance) =>
    <String, dynamic>{
      'classroomName': instance.classroomName,
      'occupiedSlots': instance.occupiedSlots,
    };
