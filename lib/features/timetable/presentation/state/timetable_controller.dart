import 'dart:async';

import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_inference.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimetableController extends Notifier<TimetableUiState> {
  @override
  TimetableUiState build() => TimetableUiState.initial();

  void setCurrentTeachingWeek(int week) {
    if (week < 1) {
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _setBaselineAndInfer(referenceDate: today, referenceWeek: week);
  }

  void updateDisplayWeek(int week) {
    if (week < 1) return;
    state = state.copyWith(displayWeek: week);
  }

  Future<void> restoreCachedTeachingWeekBaseline() async {
    final loadBaseline = ref.read(
      loadCachedTeachingWeekBaselineUseCaseProvider,
    );
    final baseline = await loadBaseline();
    if (baseline == null) {
      // No fallback; user must specify 'Today's Week' to calibrate the anchor.
      return;
    }

    final anchor = mondayOfTermWeekOne(
      referenceWeek: baseline.referenceWeek,
      referenceDate: baseline.referenceDate,
    );

    final inferred = calculateWeekIndex(DateTime.now(), anchor);

    state = state.copyWith(
      referenceWeek: baseline.referenceWeek,
      currentTeachingWeek: inferred,
      displayWeek: inferred, // Initial view is today
      termStartMonday: anchor,
      status: '已根据缓存基准自动推算到第$inferred周。',
    );
  }

  Future<void> restoreCachedTimetable() async {
    final loadCachedTimetable = ref.read(loadCachedTimetableUseCaseProvider);
    final cachedData = await loadCachedTimetable();
    if (cachedData == null) {
      return;
    }

    state = state.copyWith(data: cachedData, status: '已加载上次缓存课表。');
  }

  void _setBaselineAndInfer({
    required DateTime referenceDate,
    required int referenceWeek,
  }) {
    final safeWeek = referenceWeek < 1 ? 1 : referenceWeek;
    final anchor = mondayOfTermWeekOne(
      referenceDate: referenceDate,
      referenceWeek: safeWeek,
    );

    final inferred = calculateWeekIndex(DateTime.now(), anchor);

    state = state.copyWith(
      referenceWeek: safeWeek,
      currentTeachingWeek: inferred,
      displayWeek: inferred, // Reset view on calibration
      termStartMonday: anchor,
    );

    final cacheBaseline = ref.read(cacheTeachingWeekBaselineUseCaseProvider);
    unawaited(
      cacheBaseline(
        TeachingWeekBaseline(
          referenceDate: referenceDate,
          referenceWeek: safeWeek,
        ),
      ).catchError((_) {
        // Cache write failures should never break the interactive flow.
      }),
    );
  }

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
      final cacheTimetable = ref.read(cacheTimetableUseCaseProvider);
      try {
        await cacheTimetable(data.rows);
      } catch (_) {
        // Cache failures should not block timetable fetch success.
      }

      if (data.loginLikelySuccess) {
        final cacheCredentials = ref.read(cacheCredentialsUseCaseProvider);
        try {
          await cacheCredentials(
            LoginCredentials(username: cleanUser, password: password),
          );
        } catch (_) {
          // Cache failures should not block timetable fetch success.
        }
      }
      state = state.copyWith(
        isLoading: false,
        data: data,
        status:
            '抓取完成: 表格行=${data.rows.length}，可展示时段=${data.occurrences.length}',
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
              loweredErr.contains(
                'networkerror when attempting to fetch resource',
              ) ||
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
