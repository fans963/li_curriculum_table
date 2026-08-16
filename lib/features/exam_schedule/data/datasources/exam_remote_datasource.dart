import 'package:li_curriculum_table/core/services/app_logger.dart';
import 'package:li_curriculum_table/core/rust/api/exam.dart' as rust_api;
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;
import '../../domain/models/exam.dart';

class ExamRemoteDataSource {
  Future<List<ExamEntity>> getExams({
    required String username,
    required String password,
  }) async {
    AppLogger.instance.info(
      'Calling rust_api.getExams()...',
      tag: 'ExamRemote',
    );
    final List<rust_model.Exam> rustExams = await rust_api.getExams(
      username: username,
      password: password,
    );

    AppLogger.instance.info(
      'Rust returned ${rustExams.length} exams',
      tag: 'ExamRemote',
    );

    return rustExams
        .map(
          (e) => ExamEntity(
            session: e.session,
            courseCode: e.courseCode,
            courseName: e.courseName,
            examTime: e.examTime,
            location: e.location,
            seatNumber: e.seatNumber,
          ),
        )
        .toList();
  }
}
