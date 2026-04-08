import 'package:curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';
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
      var message = '抓取失败: $e';
      final loweredErr = err.toLowerCase();
      final isConnRefused =
          RegExp(r'errno\s*[:=]\s*111\b').hasMatch(err) ||
          loweredErr.contains('connection refused') ||
          err.contains('errno=111') ||
          err.contains('errno:111');

      if (isConnRefused) {
        final modeText = kIsWeb ? 'Web 代理模式' : '桌面/移动直连模式';
        message =
            '抓取失败: 连接被拒绝（errno=111）。\n'
            '当前模式: $modeText\n'
            '代理地址: ${ref.read(timetableCrawlerClientProvider).proxyBaseUrl}\n'
            '当前登录地址: ${ref.read(timetableCrawlerClientProvider).loginBaseUrl}\n'
            '当前课表地址: ${ref.read(timetableCrawlerClientProvider).targetUrl}\n'
            '请确认手机网络可访问这些地址（通常需校园网或校内VPN）。';
      }

      state = state.copyWith(isLoading: false, status: message);
    }
  }
}
