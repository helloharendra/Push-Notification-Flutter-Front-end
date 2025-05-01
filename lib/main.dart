import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:push_notification/admin_screen.dart';
import 'package:push_notification/firebase_options.dart';
import 'package:push_notification/homescreen.dart';
import 'package:push_notification/message_screen.dart';
import 'package:push_notification/notification_services.dart';

final navigatorKey = GlobalKey<NavigatorState>();
Future<void> _firebaseBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');

  // Ensure notification is shown even when app is in background/terminated
  await NotificationServices.showNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications
  await NotificationServices.init();

  // Handle notification when app is opened from terminated state
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState
          ?.pushNamed('/message', arguments: initialMessage);
    });
  }

  // Handle notification when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
        'Notification opened from background: ${message.notification?.title}');
    navigatorKey.currentState?.pushNamed('/message', arguments: message);
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    NotificationServices.showNotification(message);

    // Show immediate feedback for web
    if (kIsWeb) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification?.title ?? 'New Notification'),
          content: Text(message.notification?.body ?? 'No message content'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  });

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Push Notification'),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        body: const HomeScreen(),
      ),
      routes: {
        '/message': (context) => const MessageScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}
