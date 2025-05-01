import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_notification/main.dart';

class NotificationServices {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Permission granted: ${settings.authorizationStatus}');

    // For web, set up foreground notification handling
    if (kIsWeb) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, // Required to display heads-up notifications
        badge: true,
        sound: true,
      );
    } else {
      // Initialize local notifications for mobile
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          navigatorKey.currentState?.pushNamed(
            '/message',
            arguments: RemoteMessage(
              data: {'payload': response.payload ?? ''},
              notification: RemoteNotification(
                title: 'Notification',
                body: 'You tapped a notification',
              ),
            ),
          );
        },
      );
    }

    // Get and log token
    final token = await _firebaseMessaging.getToken(
      vapidKey: kIsWeb
          ? 'BKAjGem4qLzyIDPuMhZ9FPLQuIThdWAqcFkhgQyJPY6uze9QKu2vucwPymmYywoy2cqUUcVEfRUhUIA6azx0AxY'
          : null,
    );
    debugPrint('Device token: $token');

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('Token refreshed: $newToken');
    });
  }

  static Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    final apple = message.notification?.apple;

    if (notification != null) {
      if (kIsWeb) {
        // Web notifications are handled by the browser
        return;
      }

      // Mobile notifications
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
            color: Colors.blue,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
