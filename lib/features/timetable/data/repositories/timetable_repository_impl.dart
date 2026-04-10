import 'package:li_curriculum_table/features/timetable/domain/entities/course_row.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/timetable_crawler_client.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  TimetableRepositoryImpl(this._client);

  final TimetableCrawlerClient _client;

  @override
  Future<TimetableData> fetchTimetable({
    required String username,
    required String password,
  }) async {
    // The Rust-backed client now returns fully processed rows with week hints merged.
    final result = await _client.loginAndFetchSchedule(
      username: username,
      password: password,
    );

    final rows = result.rows
        .map(CourseRow.fromRust)
        .whereType<CourseRow>()
        .toList(growable: false);

    return TimetableData(
      rows: rows,
      occurrences: buildCourseOccurrences(rows),
      loginLikelySuccess: result.loginLikelySuccess,
    );
  }
}
