import 'dart:typed_data';

import 'course_occurrence.dart';
import 'course_row.dart';

class TimetableData {
  const TimetableData({
    required this.rows,
    required this.occurrences,
    required this.captchaBytes,
    required this.verifyCode,
    required this.loginLikelySuccess,
    required this.networkLogs,
  });

  final List<CourseRow> rows;
  final List<CourseOccurrence> occurrences;
  final Uint8List captchaBytes;
  final String verifyCode;
  final bool loginLikelySuccess;
  final List<String> networkLogs;
}
