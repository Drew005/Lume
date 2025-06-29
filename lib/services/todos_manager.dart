import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/todo_item.dart';

class TodosManager {
  static late Box<TodoItem> _todosBox;

  static final ValueNotifier<List<TodoItem>> todosNotifier =
      ValueNotifier<List<TodoItem>>([]);

  static Future<void> init() async {
    _todosBox = await Hive.openBox<TodoItem>('todos');
    _loadTodos();
  }

  static void _loadTodos() {
    try {
      todosNotifier.value = _todosBox.values.toList();
    } catch (e) {
      debugPrint('Error loading todos: $e');
      todosNotifier.value = [];
    }
  }

  static List<TodoItem> get allTodos => todosNotifier.value;

  static Future<void> addTodo(TodoItem todo) async {
    try {
      await _todosBox.add(todo);
      _loadTodos();
    } catch (e) {
      debugPrint('Error adding todo: $e');
      rethrow;
    }
  }

  static Future<void> updateTodo(TodoItem todo, int index) async {
    try {
      await _todosBox.putAt(index, todo.copyWith(updatedAt: DateTime.now()));
      _loadTodos();

      if (!todo.hasAlarm || todo.dueDate == null) {
        final notifications = FlutterLocalNotificationsPlugin();
        await notifications.cancel(todo.hashCode);
      }
    } catch (e) {
      debugPrint('Error updating todo: $e');
      rethrow;
    }
  }

  static Future<void> deleteTodo(int index) async {
    try {
      await _todosBox.deleteAt(index);
      _loadTodos();
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      rethrow;
    }
  }

  static Future<void> toggleTodoCompletion(int index) async {
    try {
      final todo = _todosBox.getAt(index);
      if (todo != null) {
        final updatedTodo = todo.copyWith(
          isCompleted: !todo.isCompleted,
          updatedAt: DateTime.now(),
        );
        await _todosBox.putAt(index, updatedTodo);
        _loadTodos();

        if (updatedTodo.isCompleted) {
          final notifications = FlutterLocalNotificationsPlugin();
          await notifications.cancel(todo.hashCode);
        }
      }
    } catch (e) {
      debugPrint('Error toggling todo: $e');
      rethrow;
    }
  }

  static List<TodoItem> searchTodos(String query) {
    try {
      if (query.isEmpty) return allTodos;

      final lowerQuery = query.toLowerCase();
      return _todosBox.values.where((todo) {
        return todo.title.toLowerCase().contains(lowerQuery) ||
            (todo.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('Error searching todos: $e');
      return [];
    }
  }

  static void dispose() {
    todosNotifier.dispose();
  }
}
