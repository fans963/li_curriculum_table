import 'package:curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';

class FetchTimetableUseCase {
  FetchTimetableUseCase(this._repository);

  final TimetableRepository _repository;

  Future<TimetableData> call({
    required String username,
    required String password,
  }) {
    return _repository.fetchTimetable(username: username, password: password);
  }
}
