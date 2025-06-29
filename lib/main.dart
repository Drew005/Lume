import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lume/models/note.dart';
import 'package:lume/models/todo_item.dart';
import 'package:lume/pages/home_page.dart';
import 'package:lume/services/notes_manager.dart';
import 'package:lume/services/todos_manager.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.init();

  // Configurações de inicialização de notificações
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await SharedPreferences.getInstance();

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        debugPrint('Notification payload: ${response.payload}');
      }
    },
  );

  // Solicitar permissões melhorado
  await _requestNotificationPermissions(flutterLocalNotificationsPlugin);

  // Inicialização do Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(TodoItemAdapter());
  await Hive.openBox<TodoItem>('todos');

  await NotesManager.init();
  await TodosManager.init();

  runApp(const MyApp());
}

Future<void> _requestNotificationPermissions(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    if (Platform.isAndroid) {
      // Solicitar permissão para ignorar DND (Android 6.0+)
      final notificationPolicyStatus =
          await Permission.ignoreBatteryOptimizations.request();
      if (!notificationPolicyStatus.isGranted) {
        debugPrint('Permissão para ignorar DND não concedida');
      }

      // Solicitar permissões padrão de notificação
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidPlugin?.requestNotificationsPermission();

      // Criar canal com alta prioridade
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'todo_channel',
          'Task Reminders',
          description: 'Notifications for your scheduled tasks',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
            'alarm',
          ), // Adicione um som personalizado
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 500, 250, 500]),
          bypassDnd: true,
          audioAttributesUsage:
              AudioAttributesUsage.alarm, // Define como alarme
        ),
      );
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  } catch (e) {
    debugPrint('Erro ao solicitar permissões: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          theme: ThemeManager.getLightTheme(),
          darkTheme: ThemeManager.getDarkTheme(),
          themeMode: themeMode,
          localizationsDelegates: const [
            quill.FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
        );
      },
    );
  }
}
