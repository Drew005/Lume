import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Chaves para armazenamento
  static const String _themeKey = 'app_theme';
  static const String _accentColorKey = 'accent_color';

  // Estado atual do tema
  static ThemeMode _themeMode = ThemeMode.system;
  static Color _accentColor = Colors.blueAccent;
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(_themeMode);
  static final ValueNotifier<Color> accentColorNotifier = ValueNotifier<Color>(
    _accentColor,
  );

  // Getters
  static ThemeMode get themeMode => _themeMode;
  static Color get accentColor => _accentColor;

  // Inicialização
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega o modo do tema (default: 0 = system)
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
    themeNotifier.value = _themeMode;

    // Carrega a cor de destaque
    final colorValue = prefs.getInt(_accentColorKey);
    if (colorValue != null) {
      _accentColor = Color(colorValue);
      accentColorNotifier.value = _accentColor;
    }
  }

  // Métodos para alterar o tema
  static Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    themeNotifier.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  static Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    accentColorNotifier.value = color;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.value);

    // Notifica mudança no tema para reconstruir com nova cor
    themeNotifier.notifyListeners();
  }

  // Definições dos temas
  static ThemeData getLightTheme() {
    return ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        secondary: _accentColor.withOpacity(0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Color(0x1A000000), // 10% black
        clipBehavior: Clip.none,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        primary: _accentColor,
        secondary: _accentColor.withOpacity(0.8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.black87,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        clipBehavior: Clip.none,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return _accentColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );
  }
}
