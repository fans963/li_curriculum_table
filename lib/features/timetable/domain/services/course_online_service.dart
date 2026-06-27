import 'dart:convert';

import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_format.dart';
import 'package:signals/signals.dart';

/// Manages per-course online/offline format overrides stored in secure storage.
///
/// Follows the same reactive pattern as [CourseColorService] — uses a signal
/// so UI widgets can reactively rebuild when overrides change.
class CourseOnlineService {
  CourseOnlineService(this._store);
  final SecureStorageStore _store;

  static const _key = 'timetable.course_online_overrides';

  /// Reactive map of course name → format override.
  final _overrides = signal<Map<String, CourseFormatOverride>>(const {});

  /// Bump this signal whenever overrides change, so listening widgets rebuild.
  final version = signal(0);

  // ─── Persistence ────────────────────────────────────────────────────────

  Future<void> _load() async {
    final data = await _store.readAll([_key]);
    final jsonStr = data[_key];
    if (jsonStr == null) {
      _overrides.value = {};
      return;
    }
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      _overrides.value = decoded.map(
        (k, v) => MapEntry(
          k,
          CourseFormatOverride.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      _overrides.value = {};
    }
  }

  Future<void> _save() async {
    final map = _overrides.value.map((k, v) => MapEntry(k, v.toJson()));
    await _store.writeAll({_key: jsonEncode(map)});
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Get the format override for a course, or null if not overridden.
  CourseFormatOverride? getOverride(String courseName) {
    return _overrides.value[courseName];
  }

  /// Set a format override for a course.
  Future<void> setOverride(
    String courseName,
    CourseFormatOverride override,
  ) async {
    final map = Map<String, CourseFormatOverride>.from(_overrides.value);
    map[courseName] = override;
    _overrides.value = map;
    version.value++;
    await _save();
  }

  /// Remove the format override for a course (revert to default offline).
  Future<void> removeOverride(String courseName) async {
    final map = Map<String, CourseFormatOverride>.from(_overrides.value);
    map.remove(courseName);
    _overrides.value = map;
    version.value++;
    await _save();
  }

  /// Whether the course is marked as async (no fixed time slots in grid).
  bool isAsync(String courseName) {
    final o = _overrides.value[courseName];
    return o?.format == CourseFormat.asyncOnline;
  }

  /// Whether the course is marked as live online (scheduled, online).
  bool isLiveOnline(String courseName) {
    final o = _overrides.value[courseName];
    return o?.format == CourseFormat.liveOnline;
  }

  /// Whether the course has any online classification.
  bool isOnline(String courseName) {
    final o = _overrides.value[courseName];
    return o != null && o.isOnline;
  }

  /// All course names marked as async (for the async strip).
  List<String> get asyncCourseNames => _overrides.value.entries
      .where((e) => e.value.format == CourseFormat.asyncOnline)
      .map((e) => e.key)
      .toList();

  /// Preload cache. Call once at startup.
  Future<void> preload() => _load();

  /// Force-reload from storage. Call after backup import or cache clear.
  Future<void> reload() => _load();
}
