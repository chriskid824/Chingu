import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:flutter/material.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // 1. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // Show local notification
        _richNotificationService.showNotification(
            NotificationModel.fromRemoteMessage(message)
        );
      }
    });

    // 3. Handle Background -> Foreground (Notification Click)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleMessageNavigation(message);
    });

    // 4. Handle Terminated -> Foreground (Notification Click)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }

    // 5. Token Management
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Check/Save current token if user is logged in
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
          await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _saveTokenToDatabase(String token) async {
     User? user = FirebaseAuth.instance.currentUser;
     if (user != null) {
         try {
           await _firestoreService.updateUser(user.uid, {
               'fcmToken': FieldValue.arrayUnion([token]),
           });
         } catch (e) {
           debugPrint('Error saving FCM token: $e');
         }
     }
  }

  void _handleMessageNavigation(RemoteMessage message) {
     final Map<String, dynamic> data = message.data;
     final String? actionType = data['actionType'];

     final navigator = AppRouter.navigatorKey.currentState;
     if (navigator != null && actionType != null) {
        if (actionType == 'open_chat') {
            navigator.pushNamed(AppRoutes.chatList);
        } else if (actionType == 'view_event') {
            navigator.pushNamed(AppRoutes.eventDetail);
        } else if (actionType == 'match_history') {
             navigator.pushNamed(AppRoutes.matchesList);
        } else {
             navigator.pushNamed(AppRoutes.notifications);
        }
     }
  }
}
