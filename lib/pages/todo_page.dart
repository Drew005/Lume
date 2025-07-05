import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume/pages/settings_page.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'dart:typed_data';

import '../models/todo_item.dart';
import '../services/todos_manager.dart';

class TodoPage extends StatefulWidget {
  final String searchQuery;
  const TodoPage({super.key, required this.searchQuery});
  static _TodoPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_TodoPageState>();
  }

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with AutomaticKeepAliveClientMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  late String _searchQuery;
  late TextEditingController _taskController;
  late DateTime? _dueDateTime;
  late bool _hasAlarm;
  late List<bool> _repeatDays;
  bool _isSelecting = false;
  bool get isSelecting => _isSelecting;
  Set<int> _selectedTodos = {};
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    _dueDateTime = null;
    _hasAlarm = false;
    _repeatDays = List.filled(7, false);
    _initializeNotifications();
    _cleanUpOrphanedNotifications();
    _searchQuery = widget.searchQuery;
  }

  @override
  void didUpdateWidget(covariant TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      setState(() {
        _searchQuery = widget.searchQuery;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedTodos.contains(index)) {
        _selectedTodos.remove(index);
        if (_selectedTodos.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedTodos.add(index);
        _isSelecting = true;
      }
    });
  }

  void _startSelectionMode() {
    setState(() {
      _isSelecting = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedTodos.clear();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _cleanUpOrphanedNotifications() async {
    try {
      final pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final todoIds = TodosManager.allTodos.map((t) => t.hashCode).toSet();

      for (final notification in pendingNotifications) {
        if (!todoIds.contains(notification.id)) {
          await flutterLocalNotificationsPlugin.cancel(notification.id);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  Future<void> _deleteSelectedTodos() async {
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
              'Tem certeza que deseja excluir ${_selectedTodos.length} tarefa(s)?',
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
          _selectedTodos.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndexes) {
        await _deleteTodo(index);
      }

      _exitSelectionMode();
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final enabled = await androidPlugin?.areNotificationsEnabled();
      if (enabled == false) {
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      }

      return enabled ?? false;
    }
    return true;
  }

  void _handleNotificationTap(String payload) {
    if (payload.startsWith('todo_')) {
      final todoId = int.parse(payload.split('_')[1]);
      final todoIndex = TodosManager.allTodos.indexWhere((t) => t.id == todoId);

      if (todoIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEditTodoBottomSheet(TodosManager.allTodos[todoIndex], todoIndex);
        });
      }
    }
    debugPrint('Notification tapped with payload: $payload');
  }

  tz.TZDateTime _nextInstanceOfDay(int day, DateTime dueTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      dueTime.hour,
      dueTime.minute,
      0,
    );

    while (scheduledDate.weekday != day + 1) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  Future<void> _initializeNotifications() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _handleNotificationTap(response.payload!);
          }
        },
      );

      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'todo_channel',
                'Task Reminders',
                description: 'Notifications for your scheduled tasks',
                importance: Importance.max,
              ),
            );
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleNotification(TodoItem todo) async {
    if (!_isInitialized || !todo.hasAlarm || todo.dueDate == null) {
      debugPrint('Cancelando notificação - Condições não atendidas');
      await _cancelNotification(todo);
      return;
    }

    final hasPermission = await _checkPermissions();

    try {
      final notificationId = _generateNotificationId(todo);
      debugPrint(
        'Agendando notificação para tarefa ${todo.id} com ID: $notificationId',
      );

      final androidDetails = AndroidNotificationDetails(
        'todo_channel',
        'Task Reminders',
        channelDescription: 'Notificações para suas tarefas agendadas',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        playSound: true,
        //ongoing: true,
        audioAttributesUsage:
            AudioAttributesUsage.alarm, // Define como "alarme" (ignora DND)
        channelBypassDnd: true,
        silent: false,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        color: ThemeManager.accentColor,
        enableLights: true,
        ledColor: ThemeManager.accentColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          'Você tem uma tarefa pendente',
          contentTitle: '${todo.title}',
          htmlFormatContentTitle: true,
          summaryText: 'Tarefa',
        ),
        icon: '@drawable/ic_launcher_foreground',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        colorized: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        subtitle: 'Você tem uma tarefa pendente',
        threadIdentifier: 'todo_reminder',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = tz.TZDateTime.from(todo.dueDate!, tz.local);

      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        if (todo.repeatDays.isNotEmpty) {
          for (final day in todo.repeatDays) {
            final recurringId = notificationId + day;
            final nextDate = _nextInstanceOfDay(day, scheduledDate);

            await flutterLocalNotificationsPlugin.zonedSchedule(
              recurringId,
              '${todo.title}',
              'Tarefa recorrente',
              nextDate,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: 'todo_${todo.id}',
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
        } else {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '${todo.title}',
            'Você tem uma tarefa pendente',
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'todo_${todo.id}',
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  int _generateNotificationId(TodoItem todo) {
    return todo.id % 2147483647; // 2^31 - 1
  }

  Future<void> _cancelNotification(TodoItem todo) async {
    if (!_isInitialized) return;

    try {
      final baseId = _generateNotificationId(todo);

      if (todo.repeatDays.isNotEmpty) {
        for (final day in todo.repeatDays) {
          await flutterLocalNotificationsPlugin.cancel(baseId + day);
        }
      } else {
        await flutterLocalNotificationsPlugin.cancel(baseId);
      }
      debugPrint('Notificações canceladas para tarefa ${todo.id}');
    } catch (e) {
      debugPrint('Erro ao cancelar notificação: $e');
    }
  }

  Future<void> showAddTodoBottomSheet() async {
    _taskController.clear();
    _dueDateTime = null;
    _hasAlarm = false;
    _repeatDays = List.filled(7, false);

    final result = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddTodoBottomSheet(
              taskController: _taskController,
              dueDateTime: _dueDateTime,
              hasAlarm: _hasAlarm,
              repeatDays: _repeatDays,
              onSave: (todo) {
                _dueDateTime = todo.dueDate;
                _hasAlarm = todo.hasAlarm;
                _repeatDays = List.filled(7, false);
                for (final day in todo.repeatDays) {
                  _repeatDays[day] = true;
                }
              },
            ),
          ),
    );

    if (result != null) {
      await TodosManager.addTodo(result);
      await _scheduleNotification(result);
    }
  }

  Future<void> _showEditTodoBottomSheet(TodoItem todo, int index) async {
    _taskController.text = todo.title;
    _dueDateTime = todo.dueDate;
    _hasAlarm = todo.hasAlarm;
    _repeatDays = List.filled(7, false);
    for (final day in todo.repeatDays) {
      _repeatDays[day] = true;
    }

    await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddTodoBottomSheet(
              existingTodo: todo,
              taskController: _taskController,
              dueDateTime: _dueDateTime,
              hasAlarm: _hasAlarm,
              repeatDays: _repeatDays,
              onSave: (updatedTodo) async {
                await TodosManager.updateTodo(updatedTodo, index);
                await _cancelNotification(todo);
                await _scheduleNotification(updatedTodo);
              },
            ),
          ),
    );
  }

  Future<void> _deleteTodo(int index) async {
    final todo = TodosManager.allTodos[index];
    await _cancelNotification(todo);
    await TodosManager.deleteTodo(index);
  }

  Future<void> _confirmDeleteTodo(int index) async {
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
              'Tem certeza que deseja excluir esta tarefa?',
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
      await _deleteTodo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isSelecting ? _buildSelectionAppBar(theme) : null,
      body: ValueListenableBuilder<List<TodoItem>>(
        valueListenable: TodosManager.todosNotifier,
        builder: (context, todos, _) {
          final filteredTodos =
              _searchQuery.isNotEmpty
                  ? TodosManager.searchTodos(_searchQuery)
                  : todos;
          final pendingTodos =
              filteredTodos.where((t) => !t.isCompleted).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final completedTodos =
              filteredTodos.where((t) => t.isCompleted).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 0,
                toolbarHeight: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
              ),
              if (pendingTodos.isEmpty && completedTodos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.checklist_rtl,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                          fill: 1,
                          weight: 600,
                          grade: 200,
                        ),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Nenhuma tarefa encontrada'
                              : 'Nenhuma tarefa criada',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _RoundedTopDelegate(Theme.of(context)),
              ),
              if (pendingTodos.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TodoItemCard(
                      todo: pendingTodos[index],
                      index: todos.indexOf(pendingTodos[index]),
                      onToggle:
                          (index) => TodosManager.toggleTodoCompletion(index),
                      onDelete: (index) => _confirmDeleteTodo(index),
                      onEdit: _showEditTodoBottomSheet,
                      isSelecting: _isSelecting,
                      isSelected: _selectedTodos.contains(
                        todos.indexOf(pendingTodos[index]),
                      ),
                      onSelect: _toggleSelection,
                    ),
                    childCount: pendingTodos.length,
                  ),
                ),
              if (completedTodos.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 28),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Concluídas',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (completedTodos.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TodoItemCard(
                      todo: completedTodos[index],
                      index: todos.indexOf(completedTodos[index]),
                      onToggle:
                          (index) => TodosManager.toggleTodoCompletion(index),
                      onDelete: (index) => _deleteTodo(index),
                      onEdit: _showEditTodoBottomSheet,
                      isSelecting: _isSelecting,
                      isSelected: _selectedTodos.contains(
                        todos.indexOf(completedTodos[index]),
                      ),
                      onSelect: _toggleSelection,
                    ),
                    childCount: completedTodos.length,
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.1,
                ),
              ),
            ],
          );
        },
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
      title: Text('${_selectedTodos.length} selecionadas'),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.delete_solid),
          onPressed: _deleteSelectedTodos,
          tooltip: 'Excluir selecionadas',
        ),
      ],
    );
  }
}

class AddTodoBottomSheet extends StatefulWidget {
  final TodoItem? existingTodo;
  final TextEditingController taskController;
  final DateTime? dueDateTime;
  final bool hasAlarm;
  final List<bool> repeatDays;
  final Function(TodoItem)? onSave;

  const AddTodoBottomSheet({
    super.key,
    this.existingTodo,
    required this.taskController,
    required this.dueDateTime,
    required this.hasAlarm,
    required this.repeatDays,
    this.onSave,
  });

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  late final TextEditingController _taskController;
  late DateTime? _dueDateTime;
  late bool _hasAlarm;
  late List<bool> _repeatDays;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _taskController = widget.taskController;
    _dueDateTime = widget.dueDateTime;
    _hasAlarm = widget.hasAlarm;
    _repeatDays = List.from(widget.repeatDays);
  }

  @override
  void dispose() {
    if (!_isSaved) {
      _saveChanges();
    }
    super.dispose();
  }

  void _saveChanges() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;

    final repeatDays = <int>[];
    for (var i = 0; i < _repeatDays.length; i++) {
      if (_repeatDays[i]) repeatDays.add(i);
    }

    final todo = TodoItem(
      id: widget.existingTodo?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: text,
      description: null,
      isCompleted: widget.existingTodo?.isCompleted ?? false,
      dueDate: _hasAlarm ? _dueDateTime : null,
      hasAlarm: _hasAlarm && _dueDateTime != null,
      repeatDays: repeatDays,
      createdAt: widget.existingTodo?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave?.call(todo);
    _isSaved = true;
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final DateTime now = DateTime.now();
    DateTime selectedDate = _dueDateTime ?? now.add(const Duration(minutes: 1));

    if (selectedDate.isBefore(now)) {
      selectedDate = now.add(const Duration(minutes: 1));
    }

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      minimumDate: now,
                      maximumDate: DateTime(2100),
                      initialDateTime: selectedDate,
                      minuteInterval: 1,
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime newDate) {
                        setModalState(() {
                          selectedDate = newDate;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _dueDateTime = selectedDate;
        _hasAlarm = true;
      });
    });
  }

  void _saveAndClose() {
    _saveChanges();
    final text = _taskController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final repeatDays = <int>[];
    for (var i = 0; i < _repeatDays.length; i++) {
      if (_repeatDays[i]) repeatDays.add(i);
    }

    final todo = TodoItem(
      id: widget.existingTodo?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: text,
      description: null,
      isCompleted: widget.existingTodo?.isCompleted ?? false,
      dueDate: _hasAlarm ? _dueDateTime : null,
      hasAlarm: _hasAlarm && _dueDateTime != null,
      repeatDays: repeatDays,
      createdAt: widget.existingTodo?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave?.call(todo);
    Navigator.of(context).pop(todo);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  autofocus: true,
                  maxLength: 600,
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
                    hintText: 'Digite sua tarefa...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _saveAndClose(),
                ),
              ),
              //IconButton(
              //  icon: const Icon(CupertinoIcons.checkmark_alt),
              //  onPressed: _saveAndClose,
              //),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(CupertinoIcons.clock),
          title: ValueListenableBuilder(
            valueListenable: DateFormatManager.dateFormatNotifier,
            builder: (context, dateFormat, _) {
              return ValueListenableBuilder(
                valueListenable: DateFormatManager.timeFormatNotifier,
                builder: (context, timeFormat, _) {
                  return Text(
                    _dueDateTime == null
                        ? 'Adicionar lembrete'
                        : '${DateFormat(dateFormat, 'pt_BR').format(_dueDateTime!)}   ${DateFormat(timeFormat, 'pt_BR').format(_dueDateTime!)}',
                  );
                },
              );
            },
          ),
          trailing:
              _dueDateTime != null
                  ? IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 20),
                    onPressed: () {
                      setState(() {
                        _dueDateTime = null;
                        _hasAlarm = false;
                        _repeatDays = List.filled(7, false);
                      });
                    },
                  )
                  : null,
          onTap: () => _showDateTimePicker(context),
        ),
      ],
    );
  }
}

class TodoItemCard extends StatelessWidget {
  final TodoItem todo;
  final int index;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;
  final Function(TodoItem, int) onEdit;
  final bool isSelecting;
  final bool isSelected;
  final ValueChanged<int> onSelect;

  const TodoItemCard({
    super.key,
    required this.todo,
    required this.index,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.isSelecting = false,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActuallySelected = isSelecting && isSelected;

    return Card(
      color:
          isActuallySelected
              ? ThemeManager.accentColor.withOpacity(0.2)
              : isDark
              ? Colors.grey[900]
              : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelecting) {
            onSelect(index);
          } else {
            onEdit(todo, index);
          }
        },
        onLongPress: () {
          if (!isSelecting) {
            onSelect(index);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isSelecting)
                Center(
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (value) => onToggle(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: BorderSide(
                      color:
                          todo.isCompleted
                              ? ThemeManager.accentColor
                              : Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration:
                            todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                        color:
                            todo.isCompleted
                                ? Colors.grey
                                : Theme.of(
                                  context,
                                ).textTheme.titleMedium?.color,
                      ),
                    ),
                    if (todo.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder(
                            valueListenable:
                                DateFormatManager.dateFormatNotifier,
                            builder: (context, dateFormat, _) {
                              return ValueListenableBuilder(
                                valueListenable:
                                    DateFormatManager.timeFormatNotifier,
                                builder: (context, timeFormat, _) {
                                  return Text(
                                    '${DateFormat(dateFormat, 'pt_BR').format(todo.dueDate!)}   ${DateFormat(timeFormat, 'pt_BR').format(todo.dueDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    strutStyle: const StrutStyle(leading: 0.5),
                                  );
                                },
                              );
                            },
                          ),
                          if (todo.repeatDays.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.repeat,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (isSelecting)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect(index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: isSelected ? ThemeManager.accentColor : Colors.grey,
                    width: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
