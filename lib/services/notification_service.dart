import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/core/routes/app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  FirebaseMessaging? _messagingInstance;
  FirebaseAuth? _authInstance;
  FirestoreService? _firestoreServiceInstance;
  NotificationStorageService? _storageServiceInstance;
  RichNotificationService? _richNotificationServiceInstance;

  FirebaseMessaging get _messaging => _messagingInstance ?? FirebaseMessaging.instance;
  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirestoreService get _firestoreService => _firestoreServiceInstance ?? FirestoreService();
  NotificationStorageService get _storageService => _storageServiceInstance ?? NotificationStorageService();
  RichNotificationService get _richNotificationService => _richNotificationServiceInstance ?? RichNotificationService();

  @visibleForTesting
  void setDependencies({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
    NotificationStorageService? storageService,
    RichNotificationService? richNotificationService,
  }) {
    _messagingInstance = messaging;
    _authInstance = auth;
    _firestoreServiceInstance = firestoreService;
    _storageServiceInstance = storageService;
    _richNotificationServiceInstance = richNotificationService;
  }

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Get FCM token
      try {
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          _updateFcmToken(token);
        }

        // Handle token refresh
        _messaging.onTokenRefresh.listen(_updateFcmToken);
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

    } else {
      debugPrint('User declined or has not accepted permission');
    }

    _isInitialized = true;
  }

  Future<void> _updateFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestoreService.updateUser(user.uid, {'fcmToken': token});
    }
  }

  @visibleForTesting
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message in foreground!');
    debugPrint('Message data: ${message.data}');

    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch user preferences
    UserModel? userModel = await _firestoreService.getUser(user.uid);
    if (userModel == null) return;

    // Determine notification type
    String type = message.data['type'] ?? 'system';

    // Check preferences
    if (!_shouldShowNotification(userModel, type)) {
      debugPrint('Notification suppressed by user preference: $type');
      return;
    }

    String title = message.notification?.title ?? message.data['title'] ?? '通知';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    // Handle "Show Message Preview" preference
    if (type == 'message' && !userModel.showMessagePreview) {
      body = '您有一則新訊息';
    }

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      type: type,
      title: title,
      message: body,
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await _storageService.saveNotification(notification);

    // Show local notification
    await _richNotificationService.showNotification(notification);
  }

  bool _shouldShowNotification(UserModel user, String type) {
    switch (type) {
      case 'match':
        return user.notificationMatches;
      case 'message':
        return user.notificationMessages;
      case 'event':
        return user.notificationEvents;
      case 'marketing':
        return user.notificationMarketing;
      case 'system':
      default:
        return true;
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    final actionType = message.data['actionType'];
    final navigator = AppRouter.navigatorKey.currentState;

    if (navigator != null && actionType != null) {
      switch (actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail);
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    }
  }
}
