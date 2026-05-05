import 'package:firebase_messaging/firebase_messaging.dart';
import 'trip_sync_service.dart';

/// Top-level background message handler
/// Must be a top-level function, not a class method
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Message data: ${message.data}');

  // Handle silent data message
  if (message.data.isNotEmpty) {
    // Process trip update in background
    final notified = await TripSyncService.handleBackgroundUpdate(message.data);

    if (notified) {
      print('User notified about trip update');
    } else {
      print('No notification needed - no significant changes');
    }
  }
}

/// Firebase Messaging Service
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  static late FirebaseMessaging _firebaseMessaging;

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token (for sending notifications to this device)
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');
      print('Message data: ${message.data}');

      if (message.data.isNotEmpty) {
        // Handle in foreground
        TripSyncService.handleBackgroundUpdate(message.data).then((notified) {
          if (notified) {
            print('Foreground: User notified about trip update');
          }
        });
      }
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.messageId}');
      // Navigate to trip details or app section
    });

    // Handle termination case - when app is opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.messageId}');
      // Handle initial message
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic for testing
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
