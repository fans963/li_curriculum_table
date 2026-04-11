class GradeEntity {
  final String term;
  final String courseCode;
  final String courseName;
  final String score;
  final String scoreMark;
  final double credits;
  final int totalHours;
  final String assessmentMethod;
  final String courseAttribute;
  final String courseNature;

  const GradeEntity({
    required this.term,
    required this.courseCode,
    required this.courseName,
    required this.score,
    required this.scoreMark,
    required this.credits,
    required this.totalHours,
    required this.assessmentMethod,
    required this.courseAttribute,
    required this.courseNature,
  });

  factory GradeEntity.fromJson(Map<String, dynamic> json) {
    return GradeEntity(
      term: json['term'] as String,
      courseCode: json['courseCode'] as String,
      courseName: json['courseName'] as String,
      score: json['score'] as String,
      scoreMark: json['scoreMark'] as String,
      credits: (json['credits'] as num).toDouble(),
      totalHours: json['totalHours'] as int,
      assessmentMethod: json['assessmentMethod'] as String,
      courseAttribute: json['courseAttribute'] as String,
      courseNature: json['courseNature'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'term': term,
        'courseCode': courseCode,
        'courseName': courseName,
        'score': score,
        'scoreMark': scoreMark,
        'credits': credits,
        'totalHours': totalHours,
        'assessmentMethod': assessmentMethod,
        'courseAttribute': courseAttribute,
        'courseNature': courseNature,
      };

  /// Converts non-numeric scores to their mapping values based on the provided table.
  double get numericScore {
    final double? parsed = double.tryParse(score);
    if (parsed != null) return parsed;

    // Table 4: Grade conversion mapping
    switch (score) {
      case '优': return 90.0;
      case '优-': return 87.0;
      case '良+': return 83.0;
      case '良': return 80.0;
      case '良-': return 76.0;
      case '中+': return 73.0;
      case '中': return 70.0;
      case '中-': return 66.0;
      case '及格': return 60.0;
      case '不及格': return 59.0;
      default: return 0.0;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeEntity &&
          runtimeType == other.runtimeType &&
          term == other.term &&
          courseCode == other.courseCode &&
          courseName == other.courseName &&
          score == other.score &&
          scoreMark == other.scoreMark &&
          credits == other.credits &&
          totalHours == other.totalHours &&
          assessmentMethod == other.assessmentMethod &&
          courseAttribute == other.courseAttribute &&
          courseNature == other.courseNature;

  @override
  int get hashCode =>
      term.hashCode ^
      courseCode.hashCode ^
      courseName.hashCode ^
      score.hashCode ^
      scoreMark.hashCode ^
      credits.hashCode ^
      totalHours.hashCode ^
      assessmentMethod.hashCode ^
      courseAttribute.hashCode ^
      courseNature.hashCode;
}
