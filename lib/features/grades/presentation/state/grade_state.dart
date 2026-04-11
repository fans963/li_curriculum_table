import '../../domain/models/grade.dart';

class GradeState {
  final List<GradeEntity> grades;
  final List<GradeEntity> filteredGrades;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final double weightedAverage;
  final double totalCredits;
  final double compulsoryWeightedAverage;
  final double compulsoryCredits;
  final bool needsLogin;

  const GradeState({
    this.grades = const [],
    this.filteredGrades = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.weightedAverage = 0.0,
    this.totalCredits = 0.0,
    this.compulsoryWeightedAverage = 0.0,
    this.compulsoryCredits = 0.0,
    this.needsLogin = false,
  });

  GradeState copyWith({
    List<GradeEntity>? grades,
    List<GradeEntity>? filteredGrades,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    double? weightedAverage,
    double? totalCredits,
    double? compulsoryWeightedAverage,
    double? compulsoryCredits,
    bool? needsLogin,
  }) {
    return GradeState(
      grades: grades ?? this.grades,
      filteredGrades: filteredGrades ?? this.filteredGrades,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      weightedAverage: weightedAverage ?? this.weightedAverage,
      totalCredits: totalCredits ?? this.totalCredits,
      compulsoryWeightedAverage: compulsoryWeightedAverage ?? this.compulsoryWeightedAverage,
      compulsoryCredits: compulsoryCredits ?? this.compulsoryCredits,
      needsLogin: needsLogin ?? this.needsLogin,
    );
  }
}
