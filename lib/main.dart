import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lume/models/note.dart';
import 'package:lume/models/todo_item.dart';
import 'package:lume/pages/home_page.dart';
import 'package:lume/pages/settings_page.dart';
import 'package:lume/services/notes_manager.dart';
import 'package:lume/services/todos_manager.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:lume/services/update_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:lume/pages/onboarding_page.dart';
import 'package:lume/pages/preconfig_page.dart';

import 'package:lume/services/update_manager.dart' as update_manager;
import 'package:lume/widgets/update_dialog.dart' as update_dialog;

import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await ThemeManager.init();
    await DateFormatManager.init();
    final prefs = await SharedPreferences.getInstance();
    final bool hasAcceptedTerms = prefs.getBool('hasAcceptedTerms') ?? false;
    final bool hasCompletedPreConfig =
        prefs.getBool('hasCompletedPreConfig') ?? false;

    await UpdatePreferences.init();

    await _initializeNotifications();
    await _initializeHive();
    await NotesManager.init();
    await TodosManager.init();

    runApp(
      MyApp(
        hasAcceptedTerms: hasAcceptedTerms,
        hasCompletedPreConfig: hasCompletedPreConfig,
      ),
    );
  } catch (e) {
    debugPrint('Error during initialization: $e');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app. Please restart.'),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

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
      debugPrint('Notification payload: ${response.payload}');
    },
  );

  await _requestNotificationPermissions(flutterLocalNotificationsPlugin);
}

Future<void> _requestNotificationPermissions(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    if (Platform.isAndroid) {
      final notificationPolicyStatus = await Permission
          .ignoreBatteryOptimizations
          .request();
      if (!notificationPolicyStatus.isGranted) {
        debugPrint('Battery optimization permission not granted');
      }

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestNotificationsPermission();

      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'todo_channel',
          'Task Reminders',
          description: 'Notifications for your scheduled tasks',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList(<int>[0, 500, 250, 500]),
          bypassDnd: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ledColor: ThemeManager.accentColor,
          showBadge: true,
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
    debugPrint('Error requesting notification permissions: $e');
  }
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(TodoItemAdapter());
  await Hive.openBox<TodoItem>('todos');
}

class MyApp extends StatelessWidget {
  final bool hasAcceptedTerms;
  final bool hasCompletedPreConfig;
  final Future<SharedPreferences> _prefsFuture;

  MyApp({
    Key? key, // Também atualizei para Key? para manter consistência
    required this.hasAcceptedTerms,
    required this.hasCompletedPreConfig,
  }) : _prefsFuture = SharedPreferences.getInstance(),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: MyApp.navigatorKey,
          home: FlutterSplashScreen.fadeIn(
            backgroundColor: ThemeManager.accentColor.withOpacity(0.1),
            duration: const Duration(seconds: 3),
            onInit: () async {
              debugPrint("SplashScreen Init");
            },
            onEnd: () async {
              debugPrint("SplashScreen End");
              // Adicione um delay para garantir que o MaterialApp esteja pronto
              await Future.delayed(const Duration(milliseconds: 500));
              if (MyApp.navigatorKey.currentContext != null) {
                _checkForUpdates(MyApp.navigatorKey.currentContext!);
              }
            },
            childWidget: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Substitua pelo seu GIF ou imagem
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      ThemeManager.accentColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset('assets/splash/cat.gif', height: 150),
                  ),
                  const SizedBox(height: 20),
                  //CircularProgressIndicator(
                  //  valueColor: AlwaysStoppedAnimation<Color>(
                  //    ThemeManager.accentColor,
                  //  ),
                  //),
                ],
              ),
            ),
            nextScreen: FutureBuilder<SharedPreferences>(
              future: _prefsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(); // Placeholder enquanto carrega
                }
                return _getInitialPage();
              },
            ),
          ),
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

  Widget _getInitialPage() {
    if (!hasAcceptedTerms) {
      return OnboardingPage(
        onAccept: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasAcceptedTerms', true);
          Navigator.of(MyApp.navigatorKey.currentContext!).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PreConfigPage(
                onComplete: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasCompletedPreConfig', true);
                  Navigator.of(
                    MyApp.navigatorKey.currentContext!,
                  ).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ),
          );
        },
      );
    } else if (!hasCompletedPreConfig) {
      return PreConfigPage(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasCompletedPreConfig', true);
          Navigator.of(MyApp.navigatorKey.currentContext!).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        },
      );
    } else {
      return const HomePage();
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 1));
    final autoUpdateEnabled = await UpdatePreferences.isAutoUpdateEnabled();
    if (!autoUpdateEnabled) return;

    try {
      final updateInfo = await update_manager.UpdateManager.checkForUpdates(
        includePrerelease: true, // Inclui versões beta
        includeDraft: true, // Inclui drafts
      );
      if (updateInfo != null && context.mounted) {
        // Use o NavigatorKey para garantir o contexto correto
        update_dialog.UpdateDialogHelper.showUpdateDialog(
          MyApp.navigatorKey.currentContext!,
          update_dialog.UpdateInfo(
            title: updateInfo.releaseName,
            version: updateInfo.version,
            description: updateInfo.releaseNotes,
            features: [],
            improvements: [],
            bugFixes: [],
            isForced: updateInfo.isForced,
            downloadUrl: updateInfo.downloadUrl,
            releaseDate: updateInfo.publishedAt,
          ),
        );
      } else if (context.mounted) {
        update_dialog.UpdateDialogHelper.showUpdateDialog(
          context,
          update_dialog.UpdateInfo(
            title: 'Você está atualizado!',
            version: 'Versão mais recente',
            description:
                'Seu aplicativo está na versão mais recente disponível.',
            features: [],
            improvements: [],
            bugFixes: [],
            isForced: false,
            downloadUrl: '', // URL vazia para indicar que não há atualização
            releaseDate: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        update_dialog.UpdateDialogHelper.showUpdateDialog(
          context,
          update_dialog.UpdateInfo(
            title: 'Erro ao verificar atualizações',
            version: '',
            description: 'Ocorreu um erro ao verificar atualizações: $e',
            features: [],
            improvements: [],
            bugFixes: [],
            isForced: false,
            downloadUrl: '',
            releaseDate: DateTime.now(),
          ),
        );
      }
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
