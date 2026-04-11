// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teaching_week_baseline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeachingWeekBaseline _$TeachingWeekBaselineFromJson(
  Map<String, dynamic> json,
) => _TeachingWeekBaseline(
  referenceDate: DateTime.parse(json['referenceDate'] as String),
  referenceWeek: (json['referenceWeek'] as num).toInt(),
);

Map<String, dynamic> _$TeachingWeekBaselineToJson(
  _TeachingWeekBaseline instance,
) => <String, dynamic>{
  'referenceDate': instance.referenceDate.toIso8601String(),
  'referenceWeek': instance.referenceWeek,
};
