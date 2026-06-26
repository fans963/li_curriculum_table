// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleEvent _$ScheduleEventFromJson(Map<String, dynamic> json) =>
    _ScheduleEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      enableNotification: json['enableNotification'] as bool? ?? false,
      notifyTime: json['notifyTime'] == null
          ? null
          : DateTime.parse(json['notifyTime'] as String),
    );

Map<String, dynamic> _$ScheduleEventToJson(_ScheduleEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'location': instance.location,
      'teacher': instance.teacher,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'enableNotification': instance.enableNotification,
      'notifyTime': instance.notifyTime?.toIso8601String(),
    };
