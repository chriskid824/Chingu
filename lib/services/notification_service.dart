import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';
import '../firebase_options.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Get Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // 3. Listen to Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Listen to Auth State Changes to save token on login
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }
      }
    });

    // 4. Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        final user = _auth.currentUser;
        if (user == null) return;

        // Show local notification using RichNotificationService
        _richNotificationService.showNotification(NotificationModel(
          id: message.messageId?.hashCode.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          type: message.data['type'] ?? 'system',
          title: message.notification!.title ?? '',
          message: message.notification!.body ?? '',
          imageUrl: message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
          actionType: message.data['actionType'],
          actionData: message.data['actionData'],
          createdAt: DateTime.now(),
          isRead: false,
        ));
      }
    });

    // 5. Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Handle interactions
    await _setupInteractedMessage();
  }

  Future<void> _setupInteractedMessage() async {
      // Get any messages which caused the application to open from
      // a terminated state.
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();

      // If the message also contains a data property with a "type" of "chat",
      // navigate to a chat screen
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Also handle any interaction when the app is in the background via a
      // Stream listener
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final actionType = data['actionType'];
    final actionData = data['actionData'];

    _richNotificationService.handleNavigation(actionType, actionData, null);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }
}
