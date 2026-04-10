import 'package:li_curriculum_table/core/rust/api/crawler.dart' as rust_api;
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;

class TimetableCrawlerResult {
  TimetableCrawlerResult({
    required this.loginLikelySuccess,
    required this.html,
    required this.headers,
    required this.rows,
  });

  final bool loginLikelySuccess;
  final String html;
  final List<String> headers;
  final List<rust_model.CourseRow> rows;
}

class TimetableCrawlerException implements Exception {
  TimetableCrawlerException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class TimetableCrawlerClient {
  Future<TimetableCrawlerResult> loginAndFetchSchedule({
    required String username,
    required String password,
    int maxAttempts = 5,
  }) async {
    try {
      final rust_model.TimetableRecord record = await rust_api.fetchTimetableData(
        username: username,
        password: password,
      );

      return TimetableCrawlerResult(
        loginLikelySuccess: record.loginLikelySuccess,
        html: '', // HTML parsing is now handled in Rust
        headers: record.headers,
        rows: record.rows,
      );
    } catch (e) {
      throw TimetableCrawlerException(message: 'Rust Crawler Fail: $e', cause: e);
    }
  }

  Future<void> close() async {
    // Rust client is stateless or handled internally in this refactor
  }
}
