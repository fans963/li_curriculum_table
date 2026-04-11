// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimeSlot _$TimeSlotFromJson(Map<String, dynamic> json) => _TimeSlot(
  weekday: (json['weekday'] as num).toInt(),
  startSection: (json['startSection'] as num).toInt(),
  endSection: (json['endSection'] as num).toInt(),
  startWeek: (json['startWeek'] as num).toInt(),
  endWeek: (json['endWeek'] as num).toInt(),
  weekText: json['weekText'] as String,
);

Map<String, dynamic> _$TimeSlotToJson(_TimeSlot instance) => <String, dynamic>{
  'weekday': instance.weekday,
  'startSection': instance.startSection,
  'endSection': instance.endSection,
  'startWeek': instance.startWeek,
  'endWeek': instance.endWeek,
  'weekText': instance.weekText,
};
