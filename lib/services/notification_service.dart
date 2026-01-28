import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for auth state changes to save token when user logs in
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    // Request permission
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

      // Get the token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          _showForegroundNotification(message);
        }
      });

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        // Navigation logic is typically handled by the routing system or RichNotificationService
        // But we can trigger it here if needed.
        // For now, let's rely on the system handling the tap if it was a background notification
        // Or implement specific logic if needed.
      });
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
        debugPrint('FCM Token updated in Firestore');
      } catch (e) {
        debugPrint('Error updating FCM Token: $e');
      }
    } else {
      debugPrint('User not logged in, cannot save FCM Token');
      // Optionally verify if we should save it later when user logs in
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // Convert RemoteMessage to NotificationModel
    final notification = NotificationModel(
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

    RichNotificationService().showNotification(notification);
  }
}
