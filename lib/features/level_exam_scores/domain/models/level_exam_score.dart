class LevelExamScoreEntity {
  final String courseName;
  final String writtenScore;
  final String practicalScore;
  final String totalScore;
  final String writtenGrade;
  final String practicalGrade;
  final String totalGrade;
  final String examDate;

  const LevelExamScoreEntity({
    required this.courseName,
    required this.writtenScore,
    required this.practicalScore,
    required this.totalScore,
    required this.writtenGrade,
    required this.practicalGrade,
    required this.totalGrade,
    required this.examDate,
  });

  factory LevelExamScoreEntity.fromJson(Map<String, dynamic> json) {
    return LevelExamScoreEntity(
      courseName: json['courseName'] as String,
      writtenScore: json['writtenScore'] as String,
      practicalScore: json['practicalScore'] as String,
      totalScore: json['totalScore'] as String,
      writtenGrade: json['writtenGrade'] as String,
      practicalGrade: json['practicalGrade'] as String,
      totalGrade: json['totalGrade'] as String,
      examDate: json['examDate'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'courseName': courseName,
        'writtenScore': writtenScore,
        'practicalScore': practicalScore,
        'totalScore': totalScore,
        'writtenGrade': writtenGrade,
        'practicalGrade': practicalGrade,
        'totalGrade': totalGrade,
        'examDate': examDate,
      };

  /// Whether a numeric total score is available.
  bool get hasNumericScore => totalScore.isNotEmpty && int.tryParse(totalScore) != null;

  /// Numeric total score, or null if not available.
  int? get numericScore => int.tryParse(totalScore);

  /// Display text for the score — prefer numeric, fall back to grade.
  String get displayScore {
    if (totalScore.isNotEmpty && totalScore != '0') return totalScore;
    if (totalGrade.isNotEmpty) return totalGrade;
    return '-';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelExamScoreEntity &&
          runtimeType == other.runtimeType &&
          courseName == other.courseName &&
          writtenScore == other.writtenScore &&
          practicalScore == other.practicalScore &&
          totalScore == other.totalScore &&
          writtenGrade == other.writtenGrade &&
          practicalGrade == other.practicalGrade &&
          totalGrade == other.totalGrade &&
          examDate == other.examDate;

  @override
  int get hashCode =>
      courseName.hashCode ^
      writtenScore.hashCode ^
      practicalScore.hashCode ^
      totalScore.hashCode ^
      writtenGrade.hashCode ^
      practicalGrade.hashCode ^
      totalGrade.hashCode ^
      examDate.hashCode;
}
