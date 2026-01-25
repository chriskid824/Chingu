import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/routes/app_router.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
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
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      // 2. Get Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await updateToken(token);
      }

      // 3. Listen to Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        updateToken(newToken);
      });

      // 4. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }

        // Show local notification using RichNotificationService
        _showLocalNotification(message);
      });

      // 5. Message Opened App Handler (Background/Terminated -> Open)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleMessageNavigation(message);
      });

      // 6. Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 7. Check for Initial Message (Terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via notification');
        // Delay to allow app to initialize (e.g., Auth provider to be ready)
        // Although Auth is usually quick, navigation context is needed.
        // We'll trust that by the time the frame is rendered, we can navigate?
        // Actually, we might need to wait for context.
        // For now, we call it directly, AppRouter.navigatorKey might work if MaterialApp is built.
        _handleMessageNavigation(initialMessage);
      }

      // 8. Listen to Auth Changes to update token
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          String? token = await _firebaseMessaging.getToken();
          if (token != null) {
            updateToken(token);
          }
        }
      });
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token updated in Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('Error updating FCM Token: $e');
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Construct NotificationModel from RemoteMessage
    // Prioritize data payload
    final data = message.data;

    // Fallback values from notification block
    final notification = message.notification;

    // If no useful data, skip
    if (data.isEmpty && notification == null) return;

    final String title = data['title'] ?? notification?.title ?? '新通知';
    final String body = data['message'] ?? data['body'] ?? notification?.body ?? '';
    final String type = data['type'] ?? 'system';

    // Create a temporary model to pass to RichNotificationService
    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      type: type,
      title: title,
      message: body,
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl ?? notification?.apple?.imageUrl),
      actionType: data['actionType'] ?? type, // Use type as fallback actionType if needed
      actionData: data['actionData'] ?? json.encode(data), // Pass all data if no specific actionData
      createdAt: DateTime.now(),
    );

    RichNotificationService().showNotification(model);
  }

  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    final data = message.data;
    final type = data['type']; // 'chat', 'match', 'event'

    debugPrint('Handling navigation for type: $type');

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('Navigator state is null, cannot navigate. Retrying in 1 second...');
      await Future.delayed(const Duration(seconds: 1));
      if (AppRouter.navigatorKey.currentState != null) {
         _handleMessageNavigation(message);
      }
      return;
    }

    if (type == 'chat' || type == 'message') {
      final senderId = data['senderId'];
      final chatRoomId = data['chatRoomId'];

      if (senderId != null) {
        try {
          // We need the other user's model for ChatDetailScreen
          final UserModel? userModel = await _firestoreService.getUser(senderId);
          if (userModel != null) {
            navigator.pushNamed(
              AppRoutes.chatDetail,
              arguments: {
                'chatRoomId': chatRoomId, // Might be null, but ChatDetailScreen checks it
                'otherUser': userModel,
              },
            );
          } else {
             // Fallback to chat list
             navigator.pushNamed(AppRoutes.chatList);
          }
        } catch (e) {
          debugPrint('Error fetching user for chat navigation: $e');
          navigator.pushNamed(AppRoutes.chatList);
        }
      } else {
        navigator.pushNamed(AppRoutes.chatList);
      }
    } else if (type == 'event') {
      // Navigate to event detail
      // Assuming eventId is in data
      // final eventId = data['eventId'];
      // EventDetailScreen currently doesn't take arguments, so just push
      navigator.pushNamed(AppRoutes.eventDetail);
    } else if (type == 'match') {
      // Navigate to match list or user detail
      // If we have userId, we could go to userDetail, but UserDetailScreen doesn't take args currently
      navigator.pushNamed(AppRoutes.matchesList);
    } else {
      // Default
      navigator.pushNamed(AppRoutes.notifications);
    }
  }
}
