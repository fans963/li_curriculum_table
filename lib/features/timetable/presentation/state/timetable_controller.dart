import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimetableController extends Notifier<TimetableUiState> {
  @override
  TimetableUiState build() => TimetableUiState.initial();

  Future<void> fetchAndBuild({
    required String username,
    required String password,
  }) async {
    final cleanUser = username.trim();
    if (cleanUser.isEmpty || password.isEmpty) {
      state = state.copyWith(status: '账号和密码不能为空。');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      status: '正在爬取课表并生成对比视图...',
      clearData: true,
    );

    final useCase = ref.read(fetchTimetableUseCaseProvider);

    try {
      final data = await useCase(username: cleanUser, password: password);
      state = state.copyWith(
        isLoading: false,
        data: data,
        status: '抓取完成: 表格行=${data.rows.length}，可展示时段=${data.occurrences.length}',
      );
    } catch (e) {
      final err = e.toString();
      var message = '抓取失败，请稍后重试。';
      final loweredErr = err.toLowerCase();
      final isConnRefused =
          RegExp(r'errno\s*[:=]\s*111\b').hasMatch(err) ||
          loweredErr.contains('connection refused') ||
          err.contains('errno=111') ||
          err.contains('errno:111');
      final isWebXhrNetworkError =
          kIsWeb &&
          (loweredErr.contains('xmlhttprequest onerror') ||
              loweredErr.contains('networkerror when attempting to fetch resource') ||
              loweredErr.contains('dioexception [connection error]') ||
              loweredErr.contains('dioexception [connection errorl]'));

      if (isConnRefused) {
        message = '抓取失败，网络连接不可用，请检查网络后重试。';
      } else if (isWebXhrNetworkError) {
        message = '抓取失败，代理服务暂不可用，请稍后重试。';
      }

      state = state.copyWith(isLoading: false, status: message);
    }
  }
}
