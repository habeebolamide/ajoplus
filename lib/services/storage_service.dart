import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
    if (prefs.getBool('legacy_data_cleared') != true) {
      await Hive.initFlutter();
      for (final name in ['users', 'groups', 'members', 'contributions', 'payouts', 'transactions', 'notifications']) {
        final box = await Hive.openBox(name);
        await box.clear();
        await box.close();
      }
      await prefs.setBool('legacy_data_cleared', true);
    }
  }
}
