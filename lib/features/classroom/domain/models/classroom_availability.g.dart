// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_availability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClassroomAvailability _$ClassroomAvailabilityFromJson(
  Map<String, dynamic> json,
) => _ClassroomAvailability(
  classroomName: json['classroomName'] as String,
  availability: (json['availability'] as List<dynamic>)
      .map((e) => e as bool)
      .toList(),
  hasNoClassesThisTerm: json['hasNoClassesThisTerm'] as bool? ?? false,
);

Map<String, dynamic> _$ClassroomAvailabilityToJson(
  _ClassroomAvailability instance,
) => <String, dynamic>{
  'classroomName': instance.classroomName,
  'availability': instance.availability,
  'hasNoClassesThisTerm': instance.hasNoClassesThisTerm,
};
