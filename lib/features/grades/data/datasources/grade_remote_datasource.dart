import 'package:li_curriculum_table/core/rust/api/grade.dart' as rust_api;
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;
import '../../domain/models/grade.dart';

class GradeRemoteDataSource {
  Future<List<GradeEntity>> getGrades({
    required String username,
    required String password,
  }) async {
    final List<rust_model.Grade> rustGrades = await rust_api.getGrades(
      username: username,
      password: password,
    );

    return rustGrades.map((g) => GradeEntity(
      term: g.term,
      courseCode: g.courseCode,
      courseName: g.courseName,
      score: g.score,
      scoreMark: g.scoreMark,
      credits: g.credits,
      totalHours: g.totalHours,
      assessmentMethod: g.assessmentMethod,
      courseAttribute: g.courseAttribute,
      courseNature: g.courseNature,
    )).toList();
  }
}
