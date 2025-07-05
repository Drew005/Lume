import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:lume/pages/categories_page.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/note_card.dart';
import '../widgets/category_filter_chip.dart';
import '../models/note.dart';
import '../services/notes_manager.dart';
import 'note_page.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class CombinedValueListenable extends ValueNotifier<void> {
  final List<ValueNotifier<dynamic>> listenables;

  CombinedValueListenable(this.listenables) : super(null) {
    for (final listenable in listenables) {
      listenable.addListener(_valueChanged);
    }
  }

  void _valueChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    for (final listenable in listenables) {
      listenable.removeListener(_valueChanged);
    }
    super.dispose();
  }
}

class NotesListPage extends StatefulWidget {
  final String searchQuery;
  final Function(bool isSelecting, int count) onSelectionModeChanged;
  static _NotesListPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NotesListPageState>();
  }

  const NotesListPage({
    super.key,
    required this.searchQuery,
    required this.onSelectionModeChanged,
  });

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with AutomaticKeepAliveClientMixin {
  late String _searchQuery;
  String _selectedCategory = 'Todas';
  bool _isSelecting = false;
  bool get isSelecting => _isSelecting;
  Set<int> _selectedNotes = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotesManager.init();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedNotes.contains(index)) {
        _selectedNotes.remove(index);
        if (_selectedNotes.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedNotes.add(index);
        _isSelecting = true;
      }
      widget.onSelectionModeChanged(_isSelecting, _selectedNotes.length);
    });
  }

  void _startSelectionMode() {
    setState(() {
      _isSelecting = true;
    });
    widget.onSelectionModeChanged(true, _selectedNotes.length);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedNotes.clear();
    });
    widget.onSelectionModeChanged(false, 0);
  }

  Future<void> _shareSelectedNotes() async {
    if (!mounted) return;

    try {
      final notes = NotesManager.allNotes;
      final selectedNotes =
          _selectedNotes.map((index) => notes[index]).toList();

      if (selectedNotes.isEmpty) {
        if (mounted) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.fail,
            label: 'Nenhuma nota selecionada',
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }

      String shareText = '';

      for (final note in selectedNotes) {
        final plainText = _extractPlainText(note.content);
        shareText += '${note.title.isNotEmpty ? note.title : "(Sem título)"}\n';
        shareText += '$plainText\n\n';
      }

      await Share.share(
        shareText.trim(),
        subject:
            selectedNotes.length == 1
                ? selectedNotes.first.title.isNotEmpty
                    ? selectedNotes.first.title
                    : 'Nota compartilhada'
                : '${selectedNotes.length} notas compartilhadas',
      );
    } catch (e) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Erro ao compartilhar: ${e.toString()}',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // Método auxiliar para extrair texto
  String _extractPlainText(String quillContent) {
    try {
      final contentJson = jsonDecode(quillContent);
      if (contentJson is List) {
        return contentJson
            .map((block) {
              if (block is Map && block.containsKey('insert')) {
                return block['insert'] is String ? block['insert'] : '';
              }
              return '';
            })
            .join('')
            .replaceAll('\n', ' ')
            .trim();
      }
    } catch (e) {
      return quillContent;
    }
    return quillContent;
  }

  Future<void> _deleteSelectedNotes() async {
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
              'Tem certeza que deseja excluir ${_selectedNotes.length} nota(s)?',
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

    if (confirm != true) return;

    try {
      final sortedIndexes =
          _selectedNotes.toList()..sort((a, b) => b.compareTo(a));

      for (final index in sortedIndexes) {
        await NotesManager.deleteNote(index);
      }

      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.alert,
          label: '${_selectedNotes.length} notas excluídas',
          duration: const Duration(seconds: 2),
        );
      }

      _exitSelectionMode();
    } catch (e) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Erro ao excluir notas: ${e.toString()}',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _moveSelectedNotesToCategory() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            title: const Text('Mover para categoria'),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: NotesManager.categoriesNotifier,
                  builder: (context, categories, _) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(
                            category,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, category),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            actions: [
              // Botão "Gerenciar categorias" alinhado à esquerda
              Center(
                child: TextButton.icon(
                  icon: Icon(
                    CupertinoIcons.folder,
                    size: 18,
                    color: ThemeManager.accentColor,
                  ),
                  label: Text(
                    'Gerenciar categorias',
                    style: TextStyle(color: ThemeManager.accentColor),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Fecha o diálogo atual
                    _navigateToCategories(context);
                  },
                ),
              ),
              // Substitua o Spacer por um Container com largura flexível
              Container(width: 16), // Espaçamento fixo
              // Botão "Cancelar" alinhado à direita
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
    );

    if (category != null) {
      try {
        final notes = NotesManager.allNotes;
        for (final index in _selectedNotes) {
          if (index < notes.length) {
            await NotesManager.updateNoteCategory(notes[index], category);
          }
        }

        if (mounted) {
          IconSnackBar.show(
            context,
            snackBarType: SnackBarType.alert,
            label: 'Notas movidas para $category',
            duration: const Duration(seconds: 2),
          );
        }

        _exitSelectionMode();
      } catch (e) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Erro ao mover notas: ${e.toString()}',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _navigateToCategories(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const CategoriesPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NotesListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      setState(() {
        _searchQuery = widget.searchQuery;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isSelecting ? _buildSelectionAppBar(theme) : null,
      body: CustomScrollView(
        key: PageStorageKey<String>('notes_scroll_position'),
        slivers: [
          if (!_isSelecting) _buildCategoriesAppBar(theme),
          SliverPersistentHeader(
            pinned: true,
            delegate: _RoundedTopDelegate(theme),
          ),
          ValueListenableBuilder<List<Note>>(
            valueListenable: NotesManager.notesNotifier,
            builder: (context, notes, _) {
              final sortedNotes = List<Note>.from(notes)
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              List<Note> filteredNotes =
                  _searchQuery.isNotEmpty
                      ? NotesManager.searchNotes(_searchQuery)
                      : _selectedCategory == 'Todas'
                      ? sortedNotes
                      : sortedNotes
                          .where((note) => note.category == _selectedCategory)
                          .toList();

              if (filteredNotes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.article,
                          size: 48,
                          color: theme.disabledColor,
                          fill: 1,
                          weight: 600,
                          grade: 200,
                        ),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Nenhuma nota encontrada'
                              : _selectedCategory != 'Todas'
                              ? 'Nenhuma nota nesta categoria'
                              : 'Nenhuma nota criada',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final note = filteredNotes[index];
                  final globalIndex = notes.indexOf(note);
                  return GestureDetector(
                    onLongPress: () {
                      if (!_isSelecting) {
                        _startSelectionMode();
                        _toggleSelection(globalIndex);
                      }
                    },
                    child: NoteCard(
                      note: note,
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelection(globalIndex);
                        } else {
                          _editNote(context, note);
                        }
                      },
                      onDelete: () => _confirmDeleteNote(note),
                      isSelected: _selectedNotes.contains(globalIndex),
                      isSelecting: _isSelecting,
                      onSelect: () => _toggleSelection(globalIndex),
                    ),
                  );
                }, childCount: filteredNotes.length),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildCategoriesAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 0,
      toolbarHeight: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 0,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              ValueListenableBuilder<List<String>>(
                                valueListenable:
                                    NotesManager.categoriesNotifier,
                                builder: (context, categories, _) {
                                  return Row(
                                    children: [
                                      CategoryFilterChip(
                                        category: 'Todas',
                                        selected: _selectedCategory == 'Todas',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _selectedCategory = 'Todas';
                                              _searchQuery = '';
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      for (final category in categories)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: CategoryFilterChip(
                                            category: category,
                                            selected:
                                                _selectedCategory == category,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedCategory = category;
                                                  _searchQuery = '';
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              theme.scaffoldBackgroundColor.withOpacity(1),
                              theme.scaffoldBackgroundColor.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              theme.scaffoldBackgroundColor.withOpacity(1),
                              theme.scaffoldBackgroundColor.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildSelectionAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.xmark),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedNotes.length} selecionadas'),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.share_solid),
          onPressed: _shareSelectedNotes,
          tooltip: 'Compartilhar selecionadas',
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.folder_fill_badge_plus),
          onPressed: _moveSelectedNotesToCategory,
          tooltip: 'Mover para categoria',
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.delete_solid),
          onPressed: _deleteSelectedNotes,
          tooltip: 'Excluir selecionadas',
        ),
      ],
    );
  }

  Future<void> _editNote(BuildContext context, Note note) async {
    if (_isSelecting) return;

    final index = NotesManager.allNotes.indexOf(note);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NotePage(existingNote: note, existingNoteIndex: index),
      ),
    );

    if (result == true && mounted) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.success,
        label: 'Nota atualizada com sucesso!',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _deleteNote(Note note) async {
    if (_isSelecting) return;

    try {
      final index = NotesManager.allNotes.indexOf(note);
      if (index >= 0) {
        await NotesManager.deleteNote(index);
      }
    } catch (e) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Erro ao excluir: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _confirmDeleteNote(Note note) async {
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
              'Tem certeza que deseja excluir esta nota?',
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
      await _deleteNote(note);
    }
  }
}

class _RoundedTopDelegate extends SliverPersistentHeaderDelegate {
  final ThemeData theme;
  _RoundedTopDelegate(this.theme);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: CustomPaint(
        size: const Size(double.infinity, 12),
        painter: _RoundedTopPainter(theme),
      ),
    );
  }

  @override
  double get maxExtent => 12;

  @override
  double get minExtent => 12;

  @override
  bool shouldRebuild(covariant _RoundedTopDelegate oldDelegate) {
    return oldDelegate.theme != theme;
  }
}

class _RoundedTopPainter extends CustomPainter {
  final ThemeData theme;
  _RoundedTopPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = theme.scaffoldBackgroundColor
          ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final roundedPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height * 2),
            const Radius.circular(12),
          ),
        );

    canvas.drawPath(
      Path.combine(PathOperation.difference, path, roundedPath),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundedTopPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
