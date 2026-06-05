import 'package:li_curriculum_table/core/rust/api/crawler.dart' as rust_api;
import 'package:li_curriculum_table/core/rust/crawler/model.dart' as rust_model;

class TimetableCrawlerResult {
  TimetableCrawlerResult({
    required this.loginLikelySuccess,
    required this.headers,
    required this.rows,
  });

  final bool loginLikelySuccess;
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
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final rust_model.TimetableRecord record =
            await rust_api.fetchTimetableData(
          username: username,
          password: password,
        );

        return TimetableCrawlerResult(
          loginLikelySuccess: record.loginLikelySuccess,
          headers: record.headers,
          rows: record.rows,
        );
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          // Exponential backoff: 500ms, 1500ms, ...
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    // Sanitize: never include credentials or raw exception internals in message
    throw TimetableCrawlerException(
      message: '课表获取失败，已重试$maxAttempts次。请检查网络连接或账号密码后重试。',
      cause: lastError,
    );
  }

  Future<void> close() async {
    // Rust client is stateless or handled internally in this refactor
  }
}
