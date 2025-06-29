// models/todo_item.dart
import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 2)
class TodoItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final DateTime? dueDate;

  @HiveField(5)
  final bool hasAlarm;

  @HiveField(6)
  final List<int> repeatDays; // 0=Dom, 1=Seg, ..., 6=Sab

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.hasAlarm = false,
    this.repeatDays = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  TodoItem copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool? hasAlarm,
    List<int>? repeatDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
