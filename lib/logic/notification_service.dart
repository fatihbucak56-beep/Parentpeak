import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:trusted_circle_demo/logic/backend_api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );
    await _plugin.initialize(settings: settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'parentpeak_events',
      'Terminerinnerungen',
      description: 'Erinnerungen für Familienkalender',
      importance: Importance.high,
    ));

    _initialized = true;
  }

  /// Wire up FCM: request permission, get token, register with backend,
  /// and handle foreground messages as local notifications.
  Future<void> initFcm({BackendApiClient? apiClient, String? userId}) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await messaging.getToken();
      if (token != null && apiClient != null && userId != null) {
        try {
          await apiClient.registerFcmToken(
            userId: userId,
            token: token,
          );
        } catch (_) {
          // Non-fatal: local notifications still work.
        }
      }

      // Re-register whenever the token is refreshed.
      messaging.onTokenRefresh.listen((newToken) async {
        if (apiClient != null && userId != null) {
          try {
            await apiClient.registerFcmToken(
              userId: userId,
              token: newToken,
            );
          } catch (_) {}
        }
      });

      // Show foreground FCM messages as local notifications.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            title: notification.title ?? 'Parentpeak',
            body: notification.body ?? '',
          );
        }
      });
    }
  }

  /// Display an immediate local notification (no scheduling).
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'parentpeak_events',
      'Terminerinnerungen',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> scheduleReminder(
      DateTime when, String title, String body) async {
    final now = DateTime.now();
    if (when.isBefore(now)) return; // keine Vergangenheit planen
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final id = when.millisecondsSinceEpoch % 2147483647;

    const androidDetails = AndroidNotificationDetails(
      'parentpeak_events',
      'Terminerinnerungen',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required DateTime when,
    required String title,
    required String body,
    required String reminderKey,
  }) async {
    final now = DateTime.now();
    if (when.isBefore(now)) return;

    final id = _stableNotificationId('$eventId|$reminderKey|${when.toIso8601String()}');
    final tzWhen = tz.TZDateTime.from(when, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'parentpeak_events',
      'Terminerinnerungen',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzWhen,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleStandardCalendarReminders({
    required String eventId,
    required DateTime eventStart,
    required String title,
    required String body,
  }) async {
    final entries = <({String key, DateTime when})>[
      (key: 'week_before', when: eventStart.subtract(const Duration(days: 7))),
      (key: 'day_before', when: eventStart.subtract(const Duration(days: 1))),
      (key: 'event_day', when: eventStart),
    ];

    for (final entry in entries) {
      await scheduleEventReminder(
        eventId: eventId,
        when: entry.when,
        title: title,
        body: body,
        reminderKey: entry.key,
      );
    }
  }

  int _stableNotificationId(String seed) {
    var hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7fffffff;
    }
    if (hash == 0) {
      return 1;
    }
    return hash;
  }
}
