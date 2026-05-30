import '../../domain/models/exam.dart';

class ExamState {
  final List<ExamEntity> exams;
  final List<ExamEntity> filteredExams;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool needsLogin;

  const ExamState({
    this.exams = const [],
    this.filteredExams = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.needsLogin = false,
  });

  ExamState copyWith({
    List<ExamEntity>? exams,
    List<ExamEntity>? filteredExams,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? needsLogin,
  }) {
    return ExamState(
      exams: exams ?? this.exams,
      filteredExams: filteredExams ?? this.filteredExams,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      needsLogin: needsLogin ?? this.needsLogin,
    );
  }
}
