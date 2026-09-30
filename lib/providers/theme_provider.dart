import 'package:flutter/material.dart';
import '../services/services.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode =
      ThemeMode.values[StorageService.prefs.getInt('theme')?.clamp(0, 2) ?? 0];
  void setMode(ThemeMode next) {
    mode = next;
    StorageService.prefs.setInt('theme', next.index);
    notifyListeners();
  }

  bool get reminders => StorageService.prefs.getBool('reminders') ?? true;
  void setReminders(bool enabled) {
    StorageService.prefs.setBool('reminders', enabled);
    notifyListeners();
  }
}
