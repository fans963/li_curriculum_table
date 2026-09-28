import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/app_logger.dart';
import 'package:li_curriculum_table/core/services/notification_service.dart';
import 'package:li_curriculum_table/features/todo/data/todo_repository.dart';
import 'package:li_curriculum_table/features/todo/domain/entities/course_todo.dart';
import 'package:signals/signals.dart';

/// Signal-based controller for course homework / DDL memos.
///
/// Responsibilities:
///   * Persist [CourseTodo] list through [TodoRepository].
///   * Compute convenient views: open count, sorted upcoming list,
///     per-course badge counts, etc.
///   * Coordinate DDL reminders with [NotificationService].
class TodoController {
  TodoController({
    TodoRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? sl<TodoRepository>(),
        _notificationService = notificationService ?? sl<NotificationService>();

  final TodoRepository _repository;
  final NotificationService _notificationService;

  final _todos = signal<List<CourseTodo>>(const []);
  final _loaded = signal(false);
  final _busy = signal(false);

  ReadonlySignal<List<CourseTodo>> get todos => _todos;
  ReadonlySignal<bool> get loaded => _loaded;
  ReadonlySignal<bool> get busy => _busy;

  /// All todos (including completed).
  List<CourseTodo> get all => _todos.value;

  /// Incomplete todos only, sorted by deadline ascending.
  late final openTodos = computed<List<CourseTodo>>(() {
    final list = _todos.value
        .where((t) => !t.isCompleted)
        .toList(growable: false);
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  });

  /// Upcoming incomplete todos (deadline in the future or today).
  late final upcomingTodos = computed<List<CourseTodo>>(() {
    final now = DateTime.now();
    return openTodos.value
        .where((t) => t.deadline.isAfter(now) || t.isDueToday)
        .toList(growable: false);
  });

  /// Aggregated count of open todos per course name.
  late final openCountByCourse = computed<Map<String, int>>(() {
    final map = <String, int>{};
    for (final t in openTodos.value) {
      final key = t.courseName?.trim() ?? '';
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  });

  Future<void> init() async {
    if (_loaded.value) return;
    _busy.value = true;
    try {
      final list = await _repository.loadTodos();
      _todos.value = list;
      _loaded.value = true;
      await _rescheduleAllReminders();
    } catch (e, st) {
      AppLogger.instance.error('TodoController init failed', error: e, stack: st);
    } finally {
      _busy.value = false;
    }
  }

  Future<void> addTodo(CourseTodo todo) async {
    final list = [..._todos.value, todo];
    _todos.value = list;
    await _persist();
    await _scheduleReminderFor(todo);
  }

  Future<void> updateTodo(CourseTodo todo) async {
    final list = _todos.value
        .map((t) => t.id == todo.id ? todo : t)
        .toList(growable: false);
    _todos.value = list;
    await _persist();
    await _notificationService.cancelTodoReminder(todo.id);
    await _scheduleReminderFor(todo);
  }

  Future<void> toggleCompleted(String id, {bool? completed}) async {
    final list = _todos.value.map((t) {
      if (t.id != id) return t;
      final next = completed ?? !t.isCompleted;
      return t.copyWith(
        isCompleted: next,
        completedAt: next ? DateTime.now() : null,
      );
    }).toList(growable: false);
    _todos.value = list;
    await _persist();
    final updated = list.firstWhere((t) => t.id == id);
    if (updated.isCompleted) {
      await _notificationService.cancelTodoReminder(id);
    } else {
      await _scheduleReminderFor(updated);
    }
  }

  Future<void> deleteTodo(String id) async {
    _todos.value = _todos.value.where((t) => t.id != id).toList(growable: false);
    await _persist();
    await _notificationService.cancelTodoReminder(id);
  }

  Future<void> clearCompleted() async {
    _todos.value =
        _todos.value.where((t) => !t.isCompleted).toList(growable: false);
    await _persist();
  }

  /// Open todos matching a given course name (case-insensitive contains).
  List<CourseTodo> todosForCourse(String courseName) {
    final key = courseName.trim();
    if (key.isEmpty) return const [];
    return _todos.value
        .where((t) =>
            !t.isCompleted &&
            (t.courseName?.trim().toLowerCase().contains(key.toLowerCase()) ??
                false))
        .toList(growable: false)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Future<void> _persist() async {
    try {
      await _repository.saveTodos(_todos.value);
    } catch (e, st) {
      AppLogger.instance.error(
        'Persist todos failed',
        error: e,
        stack: st,
      );
    }
  }

  Future<void> _scheduleReminderFor(CourseTodo todo) async {
    if (todo.isCompleted) return;
    if (todo.reminderMinutes <= 0) return;
    final trigger = todo.deadline.subtract(
      Duration(minutes: todo.reminderMinutes),
    );
    if (trigger.isBefore(DateTime.now())) return;
    try {
      await _notificationService.scheduleTodoReminder(
        todoId: todo.id,
        title: todo.courseName?.isNotEmpty == true
            ? '📌 ${todo.courseName} · 待办提醒'
            : '📌 课表待办提醒',
        body: todo.title,
        notifyTime: trigger,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Schedule todo reminder failed: $e');
    }
  }

  Future<void> _rescheduleAllReminders() async {
    for (final todo in _todos.value) {
      await _scheduleReminderFor(todo);
    }
  }
}
