import 'dart:convert';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/todo/domain/entities/course_todo.dart';

abstract class TodoRepository {
  Future<List<CourseTodo>> loadTodos();
  Future<void> saveTodos(List<CourseTodo> todos);
}

class TodoRepositoryImpl implements TodoRepository {
  final SecureStorageStore _store;
  static const _storageKey = 'app.course_todos';

  TodoRepositoryImpl(this._store);

  @override
  Future<List<CourseTodo>> loadTodos() async {
    try {
      final res = await _store.readAll([_storageKey]);
      final jsonStr = res[_storageKey];
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => CourseTodo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveTodos(List<CourseTodo> todos) async {
    final jsonStr = jsonEncode(todos.map((t) => t.toJson()).toList());
    await _store.writeAll({_storageKey: jsonStr});
  }
}
