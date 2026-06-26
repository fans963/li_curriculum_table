import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/notification_service.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/cached_timetable.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/teaching_week_baseline.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/timetable_data.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/schedule_event.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/schedule_events_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/teaching_week_baseline_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_mapper.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_state.dart';
import 'package:signals/signals.dart';

class TimetableController {
  final _state = signal(initialTimetableState);

  ReadonlySignal<TimetableState> get state => _state;

  // Convenience computed signals
  late final isLoading = computed(() => _state.value.isLoading);
  late final status = computed(() => _state.value.status);
  late final displayWeek = computed(() => _state.value.displayWeek);
  late final currentTeachingWeek = computed(() => _state.value.currentTeachingWeek);
  late final data = computed(() => _state.value.data);
  late final needsLogin = computed(() => _state.value.needsLogin);
  late final termStartMonday = computed(() => _state.value.termStartMonday);
  late final minWeek = computed(() => _state.value.minWeek);
  late final maxWeek = computed(() => _state.value.maxWeek);

  // Guard against concurrent fetchAndBuild / syncFromCache calls
  bool _isFetching = false;

  void setTermStartDate(DateTime date) {
    _setBaselineAndInfer(referenceDate: date, referenceWeek: 1);
  }

  void updateDisplayWeek(int week) {
    _state.value = _state.value.copyWith(displayWeek: week);
  }

  Future<void> restoreCachedTeachingWeekBaseline() async {
    final repository = sl<TeachingWeekBaselineRepository>();
    final baseline = await repository.loadBaseline();
    if (baseline == null) {
      // No cached baseline — if the user has selected a semester in settings,
      // leave termStartMonday as null so the UI prompts them to pick a start date.
      // Previously this defaulted to March 1, which was incorrect for fall semesters.
      return;
    }

    final anchor = mondayOfTermWeekOne(
      referenceWeek: baseline.referenceWeek,
      referenceDate: baseline.referenceDate,
    );

    final inferred = calculateWeekIndex(DateTime.now(), anchor)
        .clamp(_state.value.minWeek, _state.value.maxWeek);

    _state.value = _state.value.copyWith(
      referenceWeek: baseline.referenceWeek,
      currentTeachingWeek: inferred,
      displayWeek: inferred,
      termStartMonday: anchor,
      status: '已根据缓存基准自动推算到第$inferred周。',
    );
  }

  Future<void> restoreCachedTimetable() async {
    final cacheRepository = sl<TimetableCacheRepository>();
    final cachedData = await cacheRepository.loadTimetable();

    if (cachedData != null) {
      _state.value = _state.value.copyWith(
        data: TimetableData(
          rows: cachedData.rows,
          occurrences: buildCourseOccurrences(cachedData.rows),
          loginLikelySuccess: true,
        ),
        status: '',
        needsLogin: false,
      );
      _updateWeekRange(_state.value.data);
      _scheduleNotifications();
      return;
    }

    try {
      final credentialsRepository = sl<CredentialsRepository>();
      final creds = await credentialsRepository.loadCredentials();
      if (creds == null || creds.isEmpty) {
        _state.value = _state.value.copyWith(needsLogin: true);
      }
    } catch (_) {
      _state.value = _state.value.copyWith(needsLogin: true);
    }
  }

  void _updateWeekRange(TimetableData? data) {
    if (data == null || data.occurrences.isEmpty) {
      _state.value = _state.value.copyWith(minWeek: 1, maxWeek: 18);
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

    _state.value = _state.value.copyWith(minWeek: min, maxWeek: max);
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

    final inferred = calculateWeekIndex(DateTime.now(), anchor)
        .clamp(_state.value.minWeek, _state.value.maxWeek);

    _state.value = _state.value.copyWith(
      referenceWeek: safeWeek,
      currentTeachingWeek: inferred,
      displayWeek: inferred,
      termStartMonday: anchor,
    );

    final repository = sl<TeachingWeekBaselineRepository>();
    unawaited(
      repository
          .cacheBaseline(
            TeachingWeekBaseline(
              referenceDate: referenceDate,
              referenceWeek: safeWeek,
            ),
          )
          .catchError((e) {
        if (kDebugMode) {
          debugPrint('Failed to cache teaching week baseline: $e');
        }
      }),
    );
  }

  Future<void> syncFromCache() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final repository = sl<CredentialsRepository>();
      final creds = await repository.loadCredentials();
      if (creds == null || creds.isEmpty) {
        _state.value = _state.value.copyWith(needsLogin: true, status: '');
        return;
      }
      await fetchAndBuild(username: creds.username, password: creds.password);
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, status: '同步失败: $e');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchAndBuild({
    required String username,
    required String password,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    final cleanUser = username.trim();
    if (cleanUser.isEmpty || password.isEmpty) {
      _state.value = _state.value.copyWith(status: '账号和密码不能为空。');
      _isFetching = false;
      return;
    }

    _state.value = _state.value.copyWith(
      isLoading: true,
      needsLogin: false,
      status: '正在初始化 OCR 引擎 (仅需一次)...',
    );

    try {
      final ocr = sl<OcrInitializer>();
      await ocr.ensureInitialized();
    } catch (e) {
      _state.value = _state.value.copyWith(
        isLoading: false,
        status: 'OCR 引擎初始化失败: $e',
      );
      _isFetching = false;
      return;
    }

    _state.value =
        _state.value.copyWith(status: '正在爬取课表并生成对比视图...');

    final repository = sl<TimetableRepository>();

    try {
      final data = await repository.fetchTimetable(
        username: cleanUser,
        password: password,
      );

      final cacheRepository = sl<TimetableCacheRepository>();
      try {
        await cacheRepository.cacheTimetable(
          CachedTimetable(rows: data.rows, cachedAt: DateTime.now()),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to cache timetable: $e');
        }
      }

      if (data.loginLikelySuccess) {
        final credentialsRepository = sl<CredentialsRepository>();
        try {
          await credentialsRepository.cacheCredentials(
            LoginCredentials(username: cleanUser, password: password),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to cache credentials: $e');
          }
        }
      }

      _state.value = _state.value.copyWith(
        data: data,
        status: '课表同步成功，正在拉取教室、成绩与考试信息...',
      );
      _updateWeekRange(data);

      // If termStartMonday is still null, the user hasn't set a semester start date yet.
      // The settings UI will prompt them to select one.

      // Track sub-sync failures for accurate status message
      final List<String> failedSyncs = [];

      // --- Sync Classrooms ---
      try {
        _state.value =
            _state.value.copyWith(status: '正在同步教室信息...');
        await sl<ClassroomController>().syncCurrentContext();
      } catch (e, st) {
        failedSyncs.add('教室');
        if (kDebugMode) {
          debugPrint('Classroom sync failed: $e\n$st');
        }
      }

      // --- Sync Grades ---
      try {
        _state.value =
            _state.value.copyWith(status: '正在同步成绩信息...');
        await sl<GradeController>().loadGrades(forceRefresh: true);
      } catch (e, st) {
        failedSyncs.add('成绩');
        if (kDebugMode) {
          debugPrint('Grades sync failed: $e\n$st');
        }
      }

      // --- Sync Exams ---
      try {
        _state.value =
            _state.value.copyWith(status: '正在同步考试信息...');
        await sl<ExamController>().loadExams(forceRefresh: true);
      } catch (e, st) {
        failedSyncs.add('考试');
        if (kDebugMode) {
          debugPrint('Exams sync failed: $e\n$st');
        }
      }

      final String completionMsg;
      if (failedSyncs.isEmpty) {
        completionMsg = '所有信息（课表、教室、成绩、考试）同步成功！';
      } else {
        completionMsg = '课表同步成功，但${failedSyncs.join('、')}同步失败，请稍后重试。';
      }

      _state.value = _state.value.copyWith(
        isLoading: false,
        status: completionMsg,
      );

      _scheduleNotifications();
    } catch (e) {
      final err = e.toString();
      var message = '抓取失败，请稍后重试。';
      final loweredErr = err.toLowerCase();
      final isConnRefused =
          RegExp(r'errno\s*[:=]\s*111\b').hasMatch(err) ||
              loweredErr.contains('connection refused');
      final isWebXhrNetworkError = kIsWeb &&
          (loweredErr.contains('xmlhttprequest onerror') ||
              loweredErr.contains(
                  'networkerror when attempting to fetch resource') ||
              loweredErr.contains('dioexception [connection error]'));

      if (isConnRefused) {
        message = '抓取失败，网络连接不可用，请检查网络后重试。';
      } else if (isWebXhrNetworkError) {
        message = '抓取失败，代理服务暂不可用，请稍后重试。';
      }

      _state.value = _state.value.copyWith(isLoading: false, status: message);
    } finally {
      _isFetching = false;
    }
  }

  /// Schedule course notifications for the upcoming week.
  /// Fire-and-forget; errors are logged but never block the UI.
  void _scheduleNotifications() {
    final state = _state.value;
    final data = state.data;
    final termStart = state.termStartMonday;
    final week = state.currentTeachingWeek;
    if (data == null || termStart == null || week < 1) return;

    sl<NotificationService>()
        .scheduleCourseReminders(
      templates: data.occurrences,
      termStartMonday: termStart,
      currentTeachingWeek: week,
    )
        .catchError((e) {
      if (kDebugMode) debugPrint('Course notification scheduling failed: $e');
    });
  }

  // ─── Schedule Events ─────────────────────────────────────────────────────

  /// Load schedule events from storage into state.
  Future<void> loadScheduleEvents() async {
    final events = await sl<ScheduleEventsRepository>().loadEvents();
    _state.value = _state.value.copyWith(scheduleEvents: events);
  }

  /// Add a schedule event and optionally schedule a notification.
  Future<void> addScheduleEvent(ScheduleEvent event) async {
    final repo = sl<ScheduleEventsRepository>();
    final events = await repo.loadEvents();
    events.add(event);
    await repo.saveEvents(events);
    _state.value = _state.value.copyWith(scheduleEvents: events);

    if (event.enableNotification && event.notifyTime != null) {
      final idHash = event.id.hashCode.toUnsigned(31);
      await sl<NotificationService>().scheduleEventReminder(
        id: idHash,
        title: '📅 日程提醒',
        body: '${event.title}\n${event.location}',
        notifyTime: event.notifyTime!,
      );
    }
  }

  /// Remove a schedule event by ID and cancel its notification.
  Future<void> removeScheduleEvent(String eventId) async {
    final repo = sl<ScheduleEventsRepository>();
    final events = await repo.loadEvents();
    final target = events.where((e) => e.id == eventId);
    if (target.isNotEmpty && target.first.enableNotification) {
      await sl<NotificationService>().cancelEventReminder(
        eventId.hashCode.toUnsigned(31),
      );
    }
    events.removeWhere((e) => e.id == eventId);
    await repo.saveEvents(events);
    _state.value = _state.value.copyWith(scheduleEvents: events);
  }

  Future<void> clearAllCache() async {
    _state.value =
        _state.value.copyWith(isLoading: true, status: '正在清除缓存...');
    await sl<ScheduleEventsRepository>().clearEvents();
    final store = sl<SecureStorageStore>();
    await store.deleteAllExcept([
      'timetable.credentials.username',
      'timetable.credentials.password',
      'timetable.course_colors',
      // Preserve all app settings
      'proxy_enabled', 'proxy_port', 'weekly_scroll',
      'theme_mode', 'seed_color', 'use_dynamic_color',
      'design_style', 'color_scheme_type', 'enable_book_cover',
      'current_term', 'auto_size_text', 'auto_size_min_font_size',
      'timetable_text_max_lines', 'timetable_text_font_size',
      'days_visible_count', 'terms_accepted',
    ]);

    _state.value = initialTimetableState.copyWith(
      needsLogin: false,
      status: '缓存已清除。',
    );
    await sl<CourseColorService>().reload();
  }
}
