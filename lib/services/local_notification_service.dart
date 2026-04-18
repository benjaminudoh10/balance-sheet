import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (budget completion, etc.).
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Channel id bumped so devices that already created the old channel pick up
  /// [Importance.high] (Android locks importance per channel after first create).
  static const String _budgetChannelId = 'budget_completion_heads_up';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _budgetChannelId,
    'Budget reminders',
    description: 'Alerts when spending reaches a planned budget line.',
    // Default/low importance only shows in the shade; high allows heads-up banners.
    importance: Importance.high,
  );

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings darwinInit = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );
      await _plugin.initialize(settings: initSettings);

      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();

      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final MacOSFlutterLocalNotificationsPlugin? mac =
          _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      await mac?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (e, st) {
      debugPrint('LocalNotificationService init failed: $e\n$st');
      _initialized = true;
    }
  }

  Future<void> showBudgetLineReached({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }
    try {
      await ensureInitialized();
      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetChannelId,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentBanner: true,
          presentList: true,
          presentSound: true,
        ),
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e, st) {
      debugPrint('LocalNotificationService.show failed: $e\n$st');
    }
  }
}
