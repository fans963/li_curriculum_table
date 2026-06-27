import 'package:li_curriculum_table/features/timetable/data/datasources/secure_schedule_events_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/schedule_events_repository.dart';

class ScheduleEventsRepositoryImpl implements ScheduleEventsRepository {
  final SecureScheduleEventsLocalDataSource _localDataSource;

  ScheduleEventsRepositoryImpl(this._localDataSource);

  @override
  Future<List<ScheduleEvent>> loadEvents() => _localDataSource.load();

  @override
  Future<void> saveEvents(List<ScheduleEvent> events) =>
      _localDataSource.save(events);

  @override
  Future<void> clearEvents() => _localDataSource.clear();
}
