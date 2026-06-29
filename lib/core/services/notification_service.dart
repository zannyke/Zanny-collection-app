import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../cloudflare/api_client.dart';
import '../router/app_router.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background notification: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zanny_high_importance',
    'Zanny Collection',
    description: 'Notifications from Zanny Collection',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true, announcement: false,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    debugPrint('✅ Notification service initialized');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
          ),
        ),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    final route = message.data['route'] as String?;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    if (route != null && route.isNotEmpty) {
      navigator.pushNamed(route);
    } else {
      navigator.pushNamed('/orders');
    }
  }

  /// Save FCM token to Cloudflare Worker for push notifications.
  static Future<void> saveTokenForCurrentUser() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      debugPrint('🔑 FCM Token: ${token.substring(0, 20)}...');
      await ApiClient.instance.post('/api/auth/fcm-token', data: {'token': token});
    } catch (e) {
      debugPrint('⚠️ Failed to save FCM token: $e');
    }
  }

  static Future<String?> getToken() => _messaging.getToken();

  static Future<void> showLocalNotification(int id, String title, String body) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }
}
