import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/note.dart';

class NotesManager {
  static late Box<Note> _notesBox;
  static late Box<String> _categoriesBox;

  static final ValueNotifier<List<String>> categoriesNotifier =
      ValueNotifier<List<String>>([]);
  static final ValueNotifier<List<Note>> notesNotifier =
      ValueNotifier<List<Note>>([]);

  static const List<String> _defaultCategories = ['Sem Categoria'];

  static List<String> getDefaultCategories() {
    return const ['Sem Categoria'];
  }

  static Future<void> init() async {
    try {
      _notesBox = await Hive.openBox<Note>('notes');
      _categoriesBox = await Hive.openBox<String>('categories');
      _loadAllData();
    } catch (e) {
      debugPrint('Error initializing NotesManager: $e');
      rethrow;
    }
  }

  static void _loadAllData() {
    _loadCategories();
    _loadNotes();
  }

  static void _loadCategories() {
    try {
      final customCategories = _categoriesBox.values.toSet().toList();
      categoriesNotifier.value = [
        ..._defaultCategories,
        ...customCategories.where((c) => !_defaultCategories.contains(c)),
      ];
    } catch (e) {
      debugPrint('Error loading categories: $e');
      categoriesNotifier.value = List.from(_defaultCategories);
    }
  }

  static void _loadNotes() {
    try {
      notesNotifier.value = _notesBox.values.toList();
    } catch (e) {
      debugPrint('Error loading notes: $e');
      notesNotifier.value = [];
    }
  }

  static Future<void> addCategory(String category) async {
    try {
      if (category.trim().isEmpty) return;

      final trimmedCategory = category.trim();
      if (!categoriesNotifier.value.any(
        (c) => c.toLowerCase() == trimmedCategory.toLowerCase(),
      )) {
        await _categoriesBox.add(trimmedCategory);
        _loadCategories();
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  static Future<void> updateCategory(String oldName, String newName) async {
    try {
      if (newName.trim().isEmpty || newName == oldName) return;

      final index = _categoriesBox.values.toList().indexOf(oldName);
      if (index >= 0) {
        await _categoriesBox.putAt(index, newName.trim());

        final notesToUpdate =
            _notesBox.values.where((note) => note.category == oldName).toList();

        for (final note in notesToUpdate) {
          final noteIndex = _notesBox.values.toList().indexOf(note);
          await _notesBox.putAt(
            noteIndex,
            note.copyWith(category: newName, updatedAt: DateTime.now()),
          );
        }

        _loadAllData();
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  static Future<void> deleteCategory(String category) async {
    try {
      if (_defaultCategories.contains(category)) {
        throw Exception('Cannot delete default categories');
      }

      final index = _categoriesBox.values.toList().indexOf(category);
      if (index >= 0) {
        final notesToUpdate =
            _notesBox.values
                .where((note) => note.category == category)
                .toList();

        for (final note in notesToUpdate) {
          final noteIndex = _notesBox.values.toList().indexOf(note);
          await _notesBox.putAt(
            noteIndex,
            note.copyWith(
              category: _defaultCategories.first,
              updatedAt: DateTime.now(),
            ),
          );
        }

        await _categoriesBox.deleteAt(index);
        _loadAllData();
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  static List<Note> get allNotes => notesNotifier.value;

  static List<String> get allCategories => categoriesNotifier.value;

  static Future<void> addNote(Note note) async {
    try {
      if (_notesBox.isOpen) {
        await _notesBox.add(note);
        _loadNotes();
      }
    } catch (e) {
      debugPrint('Error adding note: $e');
      rethrow;
    }
  }

  static Future<void> updateNote(Note note, int index) async {
    try {
      await _notesBox.putAt(index, note.copyWith(updatedAt: DateTime.now()));
      _loadNotes();
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  static Future<void> deleteNote(int index) async {
    try {
      await _notesBox.deleteAt(index);
      _loadNotes();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  static Future<void> updateNoteCategory(Note note, String newCategory) async {
    try {
      final index = _notesBox.values.toList().indexOf(note);
      if (index >= 0) {
        await _notesBox.putAt(
          index,
          note.copyWith(category: newCategory, updatedAt: DateTime.now()),
        );
        _loadNotes();
      }
    } catch (e) {
      debugPrint('Error updating note category: $e');
      rethrow;
    }
  }

  static List<Note> searchNotes(String query) {
    try {
      if (query.isEmpty) return allNotes;

      final lowerQuery = query.toLowerCase();
      return _notesBox.values.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery) ||
            note.category.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching notes: $e');
      return [];
    }
  }

  static List<Note> filterByCategory(String category) {
    try {
      if (category == 'Todas') {
        return _notesBox.values.toList();
      }
      return _notesBox.values
          .where((note) => note.category == category)
          .toList();
    } catch (e) {
      debugPrint('Error filtering by category: $e');
      return [];
    }
  }

  static List<Note> getRecentNotes({int limit = 5}) {
    try {
      final notes = _notesBox.values.toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent notes: $e');
      return [];
    }
  }

  static Future<void> updateNoteSilently(Note note, int index) async {
    try {
      await _notesBox.putAt(index, note.copyWith(updatedAt: DateTime.now()));
      notesNotifier.value = _notesBox.values.toList();
    } catch (e) {
      debugPrint('Error silently updating note: $e');
      rethrow;
    }
  }

  static Future<void> reorderCategories(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < _defaultCategories.length ||
          newIndex < _defaultCategories.length) {
        return;
      }

      final categories = List<String>.from(categoriesNotifier.value);
      final category = categories.removeAt(oldIndex);
      categories.insert(newIndex, category);

      await _categoriesBox.clear();
      for (final cat in categories.skip(_defaultCategories.length)) {
        await _categoriesBox.add(cat);
      }

      _loadCategories();
    } catch (e) {
      debugPrint('Error reordering categories: $e');
      rethrow;
    }
  }

  static Future<void> dispose() async {
    categoriesNotifier.dispose();
    notesNotifier.dispose();
    await _notesBox.close();
    await _categoriesBox.close();
  }
}

class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int order;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? order,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
    };
  }

  static ChecklistItem fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
      order: json['order'] ?? 0,
    );
  }
}
