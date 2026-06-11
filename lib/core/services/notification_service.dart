import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../supabase/supabase_config.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

  /// Initialize FCM and local notifications — call once in main()
  static Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Set up local notifications
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Foreground notification handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was launched from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    debugPrint('✅ Notification service initialized');
  }

  /// Show a local notification when app is in foreground
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
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    // TODO: Navigate based on message.data['route'] if provided
  }

  /// Get FCM token and save to Supabase for the current user
  static Future<void> saveTokenForUser(String? userId) async {
    if (userId == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      debugPrint('🔑 FCM Token: ${token.substring(0, 20)}...');

      await SupabaseConfig.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      }, onConflict: 'user_id,token');
    } catch (e) {
      debugPrint('⚠️ Failed to save FCM token: $e');
    }
  }

  /// Get current FCM token (for debugging)
  static Future<String?> getToken() => _messaging.getToken();
}
