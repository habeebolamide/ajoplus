import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> init() => _initialization ??= _init();

  Future<void> _init() async {
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      /* In-app notifications continue on unsupported platforms. */
    }
  }

  Future<void> show(String title, String body) async {
    if (!(StorageService.prefs.getBool('reminders') ?? true)) return;
    try {
      await init();
      await plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ajo_reminders',
            'Savings reminders',
            channelDescription: 'Contribution and payout reminders',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      /* In-app notification is still saved. */
    }
  }

  Future<void> cancelScheduled() async {
    try {
      await init();
      await plugin.cancelAll();
    } catch (_) {
      /* In-app reminders remain available. */
    }
  }

  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String message,
  ) async {
    if (!(StorageService.prefs.getBool('reminders') ?? true) ||
        !when.isAfter(DateTime.now())) {
      return;
    }
    try {
      await init();
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: message,
        scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ajo_reminders',
            'Savings reminders',
            channelDescription: 'Contribution and payout reminders',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      /* In-app reminders remain available. */
    }
  }
}
