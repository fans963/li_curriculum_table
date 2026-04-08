import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';

abstract class TimetableRepository {
  Future<TimetableData> fetchTimetable({
    required String username,
    required String password,
  });
}
