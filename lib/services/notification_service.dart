import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static late FlutterLocalNotificationsPlugin _notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize the notification service
  Future<void> initialize() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions for Android
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Show a trip update notification
  Future<void> showTripUpdateNotification({
    required String flightNumber,
    required String newStatus,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'trip_updates',
          'Trip Updates',
          channelDescription: 'Notifications for trip status changes',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      flightNumber.hashCode,
      'Trip Update',
      'Flight $flightNumber is now $newStatus',
      notificationDetails,
    );
  }

  /// Show in-app snackbar-style notification
  void showBanner(String message, {String? title}) {
    // This will be handled by the app using a GlobalKey for ScaffoldMessenger
  }
}
