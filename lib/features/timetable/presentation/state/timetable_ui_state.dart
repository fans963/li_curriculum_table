import 'package:curriculum_table/features/timetable/domain/entities/timetable_data.dart';

class TimetableUiState {
  const TimetableUiState({
    required this.isLoading,
    required this.status,
    this.data,
  });

  factory TimetableUiState.initial() {
    return const TimetableUiState(
      isLoading: false,
      status: '请输入账号密码并点击“抓取并对比”。',
    );
  }

  final bool isLoading;
  final String status;
  final TimetableData? data;

  TimetableUiState copyWith({
    bool? isLoading,
    String? status,
    TimetableData? data,
    bool clearData = false,
  }) {
    return TimetableUiState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      data: clearData ? null : (data ?? this.data),
    );
  }
}
