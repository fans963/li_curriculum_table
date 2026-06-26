import '../../domain/models/level_exam_score.dart';

class LevelExamScoreState {
  final List<LevelExamScoreEntity> scores;
  final List<LevelExamScoreEntity> filteredScores;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool needsLogin;

  const LevelExamScoreState({
    this.scores = const [],
    this.filteredScores = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.needsLogin = false,
  });

  LevelExamScoreState copyWith({
    List<LevelExamScoreEntity>? scores,
    List<LevelExamScoreEntity>? filteredScores,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? needsLogin,
  }) {
    return LevelExamScoreState(
      scores: scores ?? this.scores,
      filteredScores: filteredScores ?? this.filteredScores,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      needsLogin: needsLogin ?? this.needsLogin,
    );
  }
}
