import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. Get and Save Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // 3. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // 4. Foreground Message Handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');

        if (message.notification != null) {
          final notification = _convertToNotificationModel(message);
          RichNotificationService().showNotification(notification);
        }
      });

      // 5. Background Message Handling
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 6. Message Opened App (Interact with notification in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleMessageAction(message);
      });

      // 7. Initial Message (App terminated)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageAction(initialMessage);
      }

      // 8. Listen to Auth State Changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          String? token = await _firebaseMessaging.getToken();
          if (token != null) {
            await _saveTokenToDatabase(token);
          }
        }
      });

    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       await _firestoreService.updateUser(user.uid, {'fcmToken': token});
    }
  }

  NotificationModel _convertToNotificationModel(RemoteMessage message) {
     return NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: message.data['type'] ?? 'system',
        title: message.notification?.title ?? '',
        message: message.notification?.body ?? '',
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
     );
  }

  void _handleMessageAction(RemoteMessage message) {
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];
    if (actionType != null) {
      RichNotificationService().performAction(actionType, actionData);
    }
  }
}
