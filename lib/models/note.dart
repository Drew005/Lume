import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime updatedAt;

  Note({
    required this.title,
    required this.content,
    DateTime? createdAt,
    required this.category,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  get id => null;

  Note copyWith({
    String? title,
    String? content,
    String? category,
    DateTime? updatedAt,
  }) {
    return Note(
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
