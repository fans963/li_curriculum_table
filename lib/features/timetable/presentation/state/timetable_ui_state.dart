import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';

class TimetableUiState {
  const TimetableUiState({
    required this.isLoading,
    required this.status,
    required this.currentTeachingWeek,
    required this.displayWeek,
    required this.referenceWeek,
    required this.minWeek,
    required this.maxWeek,
    this.termStartMonday,
    this.data,
    this.needsLogin = false,
  });

  factory TimetableUiState.initial() {
    return const TimetableUiState(
      isLoading: false,
      status: '',
      currentTeachingWeek: 6,
      displayWeek: 6,
      referenceWeek: 6,
      minWeek: 1,
      maxWeek: 18,
    );
  }

  final bool isLoading;
  final String status;
  final int currentTeachingWeek; // "Today's" week
  final int displayWeek; // "Viewed" week
  final int referenceWeek;
  final int minWeek;
  final int maxWeek;
  final DateTime? termStartMonday;
  final TimetableData? data;
  final bool needsLogin;

  TimetableUiState copyWith({
    bool? isLoading,
    String? status,
    int? currentTeachingWeek,
    int? displayWeek,
    int? referenceWeek,
    int? minWeek,
    int? maxWeek,
    DateTime? termStartMonday,
    TimetableData? data,
    bool clearData = false,
    bool? needsLogin,
  }) {
    return TimetableUiState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      currentTeachingWeek: currentTeachingWeek ?? this.currentTeachingWeek,
      displayWeek: displayWeek ?? this.displayWeek,
      referenceWeek: referenceWeek ?? this.referenceWeek,
      minWeek: minWeek ?? this.minWeek,
      maxWeek: maxWeek ?? this.maxWeek,
      termStartMonday: termStartMonday ?? this.termStartMonday,
      data: clearData ? null : (data ?? this.data),
      needsLogin: needsLogin ?? this.needsLogin,
    );
  }
}
