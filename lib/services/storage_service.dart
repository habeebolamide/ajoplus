import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
  }
}
