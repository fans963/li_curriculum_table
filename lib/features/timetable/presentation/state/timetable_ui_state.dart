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
  });

  factory TimetableUiState.initial() {
    return const TimetableUiState(
      isLoading: false,
      status: '请输入账号密码并点击“抓取并对比”。',
      currentTeachingWeek: 1,
      displayWeek: 1,
      referenceWeek: 1,
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
    );
  }
}
