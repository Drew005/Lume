import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePreferences {
  static const String _autoUpdateKey = 'autoUpdateEnabled';
  static final ValueNotifier<bool> autoUpdateNotifier = ValueNotifier<bool>(
    true,
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    autoUpdateNotifier.value = prefs.getBool(_autoUpdateKey) ?? true;
  }

  static Future<void> setAutoUpdateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateKey, enabled);
    autoUpdateNotifier.value = enabled;
  }

  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoUpdateKey) ?? true;
  }
}
