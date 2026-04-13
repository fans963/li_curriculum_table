import 'dart:async';

import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_state.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';

part 'timetable_controller.g.dart';

@riverpod
class TimetableController extends _$TimetableController {
  @override
  TimetableState build() => initialTimetableState;

  void setTermStartDate(DateTime date) {
    _setBaselineAndInfer(referenceDate: date, referenceWeek: 1);
  }

  void updateDisplayWeek(int week) {
    if (week < state.minWeek || week > state.maxWeek) return;
    state = state.copyWith(displayWeek: week);
  }

  Future<void> restoreCachedTeachingWeekBaseline() async {
    final repository = ref.read(teachingWeekBaselineRepositoryProvider);
    final baseline = await repository.loadBaseline();
    if (baseline == null) {
      // Default to March 1st of current year if no cache
      final now = DateTime.now();
      setTermStartDate(DateTime(now.year, 3, 1));
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
      displayWeek: inferred,
      termStartMonday: anchor,
      status: '已根据缓存基准自动推算到第$inferred周。',
    );
  }

  Future<void> restoreCachedTimetable() async {
    final cacheRepository = ref.read(timetableCacheRepositoryProvider);
    final cachedData = await cacheRepository.loadTimetable();
    
    if (cachedData != null) {
      state = state.copyWith(
        data: TimetableData(
          rows: cachedData.rows,
          occurrences: buildCourseOccurrences(cachedData.rows),
          loginLikelySuccess: true,
        ),
        status: '',
        needsLogin: false,
      );
      _updateWeekRange(state.data);
      return;
    }

    // No cache — check if credentials exist to determine needsLogin state
    try {
      final credentialsRepository = ref.read(credentialsRepositoryProvider);
      final creds = await credentialsRepository.loadCredentials();
      if (creds == null || creds.isEmpty) {
        state = state.copyWith(needsLogin: true);
      }
    } catch (_) {
      state = state.copyWith(needsLogin: true);
    }
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
      displayWeek: inferred,
      termStartMonday: anchor,
    );

    final repository = ref.read(teachingWeekBaselineRepositoryProvider);
    unawaited(
      repository.cacheBaseline(
        TeachingWeekBaseline(
          referenceDate: referenceDate,
          referenceWeek: safeWeek,
        ),
      ).catchError((_) {}),
    );
  }

  Future<void> syncFromCache() async {
    try {
      final repository = ref.read(credentialsRepositoryProvider);
      final creds = await repository.loadCredentials();
      if (creds == null || creds.isEmpty) {
        state = state.copyWith(needsLogin: true, status: '');
        return;
      }
      await fetchAndBuild(username: creds.username, password: creds.password);
    } catch (e) {
      state = state.copyWith(isLoading: false, status: '同步失败: $e');
    }
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
      needsLogin: false,
      status: '正在初始化 OCR 引擎 (仅需一次)...',
    );

    try {
      await ref.read(ocrInitializerProvider).ensureInitialized();
    } catch (e) {
      state = state.copyWith(isLoading: false, status: 'OCR 引擎初始化失败: $e');
      return;
    }

    state = state.copyWith(status: '正在爬取课表并生成对比视图...');

    final repository = ref.read(timetableRepositoryProvider);

    try {
      final data = await repository.fetchTimetable(username: cleanUser, password: password);
      
      final cacheRepository = ref.read(timetableCacheRepositoryProvider);
      try {
        await cacheRepository.cacheTimetable(
          CachedTimetable(rows: data.rows, cachedAt: DateTime.now()),
        );
      } catch (_) {}

      if (data.loginLikelySuccess) {
        final credentialsRepository = ref.read(credentialsRepositoryProvider);
        try {
          await credentialsRepository.cacheCredentials(
            LoginCredentials(username: cleanUser, password: password),
          );
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        data: data,
        status: '抓取完成: 表格行=${data.rows.length}，可展示时段=${data.occurrences.length}',
      );
      _updateWeekRange(data);

      if (state.termStartMonday == null) {
        final now = DateTime.now();
        setTermStartDate(DateTime(now.year, 3, 1));
      }
    } catch (e) {
      final err = e.toString();
      var message = '抓取失败，请稍后重试。';
      final loweredErr = err.toLowerCase();
      final isConnRefused =
          RegExp(r'errno\s*[:=]\s*111\b').hasMatch(err) ||
          loweredErr.contains('connection refused');
      final isWebXhrNetworkError =
          kIsWeb &&
          (loweredErr.contains('xmlhttprequest onerror') ||
              loweredErr.contains('networkerror when attempting to fetch resource') ||
              loweredErr.contains('dioexception [connection error]'));

      if (isConnRefused) {
        message = '抓取失败，网络连接不可用，请检查网络后重试。';
      } else if (isWebXhrNetworkError) {
        message = '抓取失败，代理服务暂不可用，请稍后重试。';
      }

      state = state.copyWith(isLoading: false, status: message);
    }
  }

  Future<void> clearAllCache() async {
    state = state.copyWith(isLoading: true, status: '正在清除缓存...');
    final store = ref.read(secureStorageStoreProvider);
    await store.deleteAllExcept([
      'timetable.credentials.username',
      'timetable.credentials.password',
    ]);

    state = initialTimetableState.copyWith(
      needsLogin: false,
      status: '缓存已清除。',
    );
  }
}
