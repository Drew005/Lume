import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lume/models/todo_item.dart';
import 'package:lume/pages/note_page.dart';
import 'package:lume/pages/categories_page.dart';
import 'package:lume/pages/notes_list_page.dart';
import 'package:lume/pages/todo_page.dart';
import 'package:lume/services/todos_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lume/pages/settings_page.dart';
import 'package:lume/services/theme_manager.dart';

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final String _searchQuery = '';

  late AnimationController _widthAnimationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();

    _widthAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = CurvedAnimation(
      parent: _widthAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _widthAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "LUME",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(
                CupertinoIcons.folder,
                fill: 1,
                weight: 700,
                grade: 200,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => _navigateToCategories(context),
              tooltip: 'Gerenciar categorias',
            ),
          IconButton(
            icon: Icon(
              CupertinoIcons.settings,
              fill: 1,
              weight: 700,
              grade: 200,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _widthAnimationController.forward(from: 0);
        },
        children: [
          KeepAlivePage(
            child: NotesListPage(
              key: const PageStorageKey<String>('notes_list_page'),
              searchQuery: _searchQuery,
              onSelectionModeChanged: (bool isSelecting, int count) {},
            ),
          ),
          KeepAlivePage(
            child: TodoPage(
              key: const PageStorageKey<String>('notes_list_page'),
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedBuilder(
        animation: _widthAnimation,
        builder: (context, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (_currentIndex == 0) {
                _addNewNote(context);
              } else {
                _addNewTask(context);
              }
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _currentIndex == 0 ? Symbols.article : Symbols.checklist,
                key: ValueKey<int>(_currentIndex),
                size: 24,
                color: Colors.white,
              ),
            ),
            label: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.centerLeft,
              child: Text(
                _currentIndex == 0 ? 'Nova Nota' : 'Nova Tarefa',
                key: ValueKey<int>(_currentIndex),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: ThemeManager.accentColor,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            _widthAnimationController.forward(from: 0);
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Symbols.article,
                fill: 1,
                weight: 600,
                grade: 200,
                color:
                    _currentIndex == 0
                        ? ThemeManager.accentColor
                        : isDark
                        ? Colors.grey.withAlpha(150)
                        : Colors.grey[600],
              ),
              label: 'Notas',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Symbols.checklist,
                fill: 1,
                weight: 700,
                grade: 200,
                color:
                    _currentIndex == 1
                        ? ThemeManager.accentColor
                        : isDark
                        ? Colors.grey.withAlpha(150)
                        : Colors.grey[600],
              ),
              label: 'Tarefas',
            ),
          ],
          selectedItemColor: ThemeManager.accentColor,
          unselectedItemColor:
              isDark ? Colors.grey.withAlpha(150) : Colors.grey[600],
          backgroundColor: isDark ? Colors.black : Colors.grey[100],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
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
    setState(() {});
  }

  Future<void> _addNewNote(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const NotePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

  Future<void> _addNewTask(BuildContext context) async {
    final result = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddTodoBottomSheet(
            taskController: TextEditingController(),
            dueDateTime: null,
            hasAlarm: false,
            repeatDays: List.filled(7, false),
            onSave: (todo) {
              TodosManager.addTodo(todo);
            },
          ),
        );
      },
    );

    if (result != null) {
      setState(() {});
    }
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const SettingsPage(),
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
}
