import 'dart:async';

import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/core/rust/api/crawler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';

class TimetableController extends Notifier<TimetableUiState> {
  static bool _isOcrInitialized = false;

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
    if (week < state.minWeek || week > state.maxWeek) return;
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

    final inferred = calculateWeekIndex(DateTime.now(), anchor).clamp(state.minWeek, state.maxWeek);

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
    _updateWeekRange(cachedData);
  }

  void _updateWeekRange(TimetableData? data) {
    if (data == null || data.occurrences.isEmpty) {
      state = state.copyWith(minWeek: 1, maxWeek: 18);
      return;
    }

    int min = 1;
    int max = 18;

    bool initialized = false;
    for (final occ in data.occurrences) {
      if (occ.startWeek != null && occ.endWeek != null) {
        if (!initialized) {
          min = occ.startWeek!;
          max = occ.endWeek!;
          initialized = true;
        } else {
          if (occ.startWeek! < min) min = occ.startWeek!;
          if (occ.endWeek! > max) max = occ.endWeek!;
        }
      }
    }

    // Fallback if no valid week indices found
    if (!initialized) {
      min = 1;
      max = 18;
    }

    state = state.copyWith(minWeek: min, maxWeek: max);
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

    final inferred = calculateWeekIndex(DateTime.now(), anchor).clamp(state.minWeek, state.maxWeek);

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
      status: '正在初始化 OCR 引擎 (仅需一次)...',
      clearData: true,
    );

    try {
      if (!_isOcrInitialized) {
        final ByteData modelData = await rootBundle.load('assets/models/common_pruned.onnx');
        initOcrEngine(modelBytes: modelData.buffer.asUint8List());
        _isOcrInitialized = true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, status: 'OCR 引擎初始化失败: $e');
      return;
    }

    state = state.copyWith(status: '正在爬取课表并生成对比视图...');

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
      _updateWeekRange(data);

      if (state.termStartMonday == null) {
        final now = DateTime.now();
        _setBaselineAndInfer(
          referenceDate: DateTime(now.year, now.month, now.day),
          referenceWeek: 6,
        );
      }
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
