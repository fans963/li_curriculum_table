import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';

class TimetableUiState {
  const TimetableUiState({
    required this.isLoading,
    required this.status,
    required this.currentTeachingWeek,
    required this.referenceWeek,
    this.data,
  });

  factory TimetableUiState.initial() {
    return TimetableUiState(
      isLoading: false,
      status: '请输入账号密码并点击“抓取并对比”。',
      currentTeachingWeek: 1,
      referenceWeek: 1,
    );
  }

  final bool isLoading;
  final String status;
  final int currentTeachingWeek;
  final int referenceWeek;
  final TimetableData? data;

  TimetableUiState copyWith({
    bool? isLoading,
    String? status,
    int? currentTeachingWeek,
    int? referenceWeek,
    TimetableData? data,
    bool clearData = false,
  }) {
    return TimetableUiState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      currentTeachingWeek: currentTeachingWeek ?? this.currentTeachingWeek,
      referenceWeek: referenceWeek ?? this.referenceWeek,
      data: clearData ? null : (data ?? this.data),
    );
  }
}
