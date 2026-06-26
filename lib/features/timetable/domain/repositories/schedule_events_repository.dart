import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';

abstract class ScheduleEventsRepository {
  Future<List<ScheduleEvent>> loadEvents();
  Future<void> saveEvents(List<ScheduleEvent> events);
  Future<void> clearEvents();
}
