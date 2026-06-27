import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_event.freezed.dart';
part 'schedule_event.g.dart';

@freezed
abstract class ScheduleEvent with _$ScheduleEvent {
  const factory ScheduleEvent({
    required String id,
    required String title,
    @Default('') String location,
    @Default('') String teacher,
    required DateTime start,
    required DateTime end,
    @Default(false) bool enableNotification,
    DateTime? notifyTime,
  }) = _ScheduleEvent;

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEventFromJson(json);
}
