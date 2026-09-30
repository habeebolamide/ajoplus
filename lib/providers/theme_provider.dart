import 'package:flutter/material.dart';
import '../services/services.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode =
      ThemeMode.values[StorageService.prefs.getInt('theme')?.clamp(0, 2) ?? 0];
  Future<void> setMode(ThemeMode next) async {
    await StorageService.prefs.setInt('theme', next.index);
    mode = next;
    notifyListeners();
  }

  bool get reminders => StorageService.prefs.getBool('reminders') ?? true;
  Future<void> setReminders(bool enabled) async {
    await StorageService.prefs.setBool('reminders', enabled);
    notifyListeners();
  }
}
