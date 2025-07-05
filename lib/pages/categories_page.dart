import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lume/services/theme_manager.dart';
import '../services/notes_manager.dart';
import '../models/note.dart';
import 'dart:ui' show lerpDouble;

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _newCategoryController = TextEditingController();
  final Map<String, TextEditingController> _editControllers = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeEditControllers();
  }

  void _initializeEditControllers() {
    for (var category in NotesManager.categoriesNotifier.value) {
      if (!_isDefaultCategory(category)) {
        _editControllers[category] = TextEditingController(text: category);
      }
    }
  }

  bool _isDefaultCategory(String category) {
    return NotesManager.getDefaultCategories().contains(category);
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    _scrollController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.removeListener(() {});
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.add,
              fill: 1,
              weight: 700,
              grade: 200,
            ),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Adicionar categoria',
          ),
        ],
      ),
      body: Container(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: NotesManager.categoriesNotifier,
          builder: (context, categories, _) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(canvasColor: Colors.transparent),
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  scrollController: _scrollController,
                  itemCount: categories.length,
                  // Adiciona proxyDecorator para controlar o visual durante o arrastar
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final t = Curves.easeInOut.transform(animation.value);
                        final elevation = lerpDouble(0, 6, t)!;
                        final scale = lerpDouble(1, 1.02, t)!;

                        return Transform.scale(
                          scale: scale,
                          child: Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryTile(category, index);
                  },
                  onReorder: (oldIndex, newIndex) {
                    // Previne o flicker ao fazer a validação antes
                    if (_isDefaultCategory(categories[oldIndex])) return;

                    // Ajusta o índice apenas se necessário
                    if (oldIndex < newIndex) newIndex--;

                    // Chama o método de reordenação sem await para evitar delay
                    NotesManager.reorderCategories(oldIndex, newIndex);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String category, int index) {
    final isDefault = _isDefaultCategory(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _focusNodes[category] ??= FocusNode();

    // Adiciona listener para salvar quando o foco é perdido
    _focusNodes[category]!.addListener(() {
      if (!_focusNodes[category]!.hasFocus &&
          _editControllers[category] != null &&
          _editControllers[category]!.text != category) {
        _updateCategory(category, _editControllers[category]!.text);
      }
    });

    return Card(
      key: ValueKey(category),
      color: isDark ? Colors.grey[900] : Colors.grey[300],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading:
            isDefault
                ? null
                : const Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 20,
                  color: Colors.grey,
                ),
        title:
            isDefault
                ? Text(category, style: TextStyle(color: Colors.grey[600]))
                : TextField(
                  focusNode: _focusNodes[category]!,
                  controller: _editControllers[category],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  maxLength: 100,
                  maxLines: null,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) {
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nome da categoria',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (newName) {
                    _updateCategory(category, newName);
                    _focusNodes[category]!.unfocus();
                  },
                ),
        trailing:
            isDefault
                ? null
                : IconButton(
                  icon: const Icon(
                    CupertinoIcons.delete,
                    fill: 1,
                    weight: 700,
                    grade: 200,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDeleteCategory(category),
                ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            title: Text(
              'Nova Categoria',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: TextField(
              controller: _newCategoryController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              maxLength: 100,
              maxLines: null,
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Nome da categoria',
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: ThemeManager.accentColor),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (_newCategoryController.text.trim().isNotEmpty) {
                    await _addCategory(_newCategoryController.text.trim());
                    if (mounted) {
                      _newCategoryController.clear();
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  'Adicionar',
                  style: TextStyle(color: ThemeManager.accentColor),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _addCategory(String category) async {
    await NotesManager.addCategory(category);
    _editControllers[category] = TextEditingController(text: category);
  }

  Future<void> _updateCategory(String oldName, String newName) async {
    newName = newName.trim();
    if (newName.isEmpty || newName == oldName) return;

    if (NotesManager.categoriesNotifier.value.contains(newName)) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'A categoria "$newName" já existe',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    final notesBox = Hive.box<Note>('notes');
    final notesToUpdate =
        notesBox.values.where((note) => note.category == oldName).toList();

    for (final note in notesToUpdate) {
      final index = notesBox.values.toList().indexOf(note);
      await notesBox.putAt(
        index,
        note.copyWith(category: newName, updatedAt: DateTime.now()),
      );
    }

    await NotesManager.updateCategory(oldName, newName);

    // Atualiza os controllers e focus nodes
    final controller = _editControllers.remove(oldName)!;
    final focusNode = _focusNodes.remove(oldName)!;
    _editControllers[newName] = controller;
    _focusNodes[newName] = focusNode;

    // Atualiza o texto no controller
    controller.text = newName;
  }

  Future<void> _confirmDeleteCategory(String category) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            title: Text(
              'Confirmar exclusão',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              'Tem certeza que deseja excluir a categoria "$category"?',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _deleteCategory(category);
    }
  }

  Future<void> _deleteCategory(String category) async {
    final notesBox = Hive.box<Note>('notes');
    final notesToUpdate =
        notesBox.values.where((note) => note.category == category).toList();

    for (final note in notesToUpdate) {
      final index = notesBox.values.toList().indexOf(note);
      await notesBox.putAt(
        index,
        note.copyWith(category: 'Sem Categoria', updatedAt: DateTime.now()),
      );
    }

    await NotesManager.deleteCategory(category);
    _editControllers.remove(category);
  }
}

// Adicione este import no topo do arquivo se não estiver presente
