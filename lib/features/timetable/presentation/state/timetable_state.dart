import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';

part 'timetable_state.freezed.dart';

@freezed
abstract class TimetableState with _$TimetableState {
  const factory TimetableState({
    required bool isLoading,
    required String status,
    required int currentTeachingWeek,
    required int displayWeek,
    required int referenceWeek,
    required int minWeek,
    required int maxWeek,
    DateTime? termStartMonday,
    TimetableData? data,
    @Default(false) bool needsLogin,
  }) = _TimetableState;
}

const initialTimetableState = TimetableState(
  isLoading: false,
  status: '',
  currentTeachingWeek: 1,
  displayWeek: 1,
  referenceWeek: 1,
  minWeek: 1,
  maxWeek: 18,
);
