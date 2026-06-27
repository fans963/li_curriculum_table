import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:signals/signals.dart';

/// Manages per-course custom color overrides stored in secure storage.
/// Uses a signal so UI widgets can reactively rebuild when colors change.
class CourseColorService {
  CourseColorService(this._store);
  final SecureStorageStore _store;

  static const _key = 'timetable.course_colors';

  /// Reactive map of course name → ARGB int.
  final _colors = signal<Map<String, int>>(const {});

  /// Bump this signal whenever colors change, so listening widgets rebuild.
  final version = signal(0);

  Future<void> _load() async {
    final data = await _store.readAll([_key]);
    final jsonStr = data[_key];
    if (jsonStr == null) {
      _colors.value = {};
      return;
    }
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      _colors.value = decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      _colors.value = {};
    }
  }

  /// Get the custom color for a course, or null if not customized.
  Color? getColor(String courseName) {
    final value = _colors.value[courseName];
    return value != null ? Color(value) : null;
  }

  /// Set a custom color for a course.
  Future<void> setColor(String courseName, Color color) async {
    final map = Map<String, int>.from(_colors.value);
    map[courseName] = color.toARGB32();
    _colors.value = map;
    version.value++;
    await _store.writeAll({_key: jsonEncode(map)});
  }

  /// Remove the custom color for a course (revert to default).
  Future<void> removeColor(String courseName) async {
    final map = Map<String, int>.from(_colors.value);
    map.remove(courseName);
    _colors.value = map;
    version.value++;
    await _store.writeAll({_key: jsonEncode(map)});
  }

  /// Preload cache. Call once at startup.
  Future<void> preload() => _load();

  /// Force-reload from storage. Call after backup import or cache clear.
  Future<void> reload() => _load();
}
