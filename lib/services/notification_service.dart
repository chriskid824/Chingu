import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize RichNotificationService with tap handler
    await _richNotificationService.initialize(
      onNotificationTap: _handleNotificationTap,
    );

    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background click (System Notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundClick);

    // Handle terminated click (System Notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundClick(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Determine user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Parse data
    final data = message.data;
    final String type = data['type'] ?? 'system';

    // Determine A/B Group and Content
    final group = _abService.getGroup(userId);
    final notificationType = _getNotificationType(type);

    // Construct params for AB Service
    final Map<String, dynamic> params = Map<String, dynamic>.from(data);

    final content = _abService.getContent(userId, notificationType, params: params);

    // Create NotificationModel
    final notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final notification = NotificationModel(
      id: notificationId,
      userId: userId,
      type: type,
      title: content.title,
      message: content.body,
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
      trackingData: {
        'groupId': group.toString().split('.').last, // 'control' or 'variant'
        'originalType': type,
      },
    );

    // Show Notification
    await _richNotificationService.showNotification(notification);

    // Track Send
    await _trackEvent('send', notification);
  }

  void _handleBackgroundClick(RemoteMessage message) {
    // Logic to track click from background/terminated (System Notification)
    final data = message.data;
    final notificationId = message.messageId ?? 'unknown';
    final userId = FirebaseAuth.instance.currentUser?.uid;

    String? groupId;
    if (userId != null) {
       groupId = _abService.getGroup(userId).toString().split('.').last;
    }

    _firestoreService.logNotificationEvent({
      'event': 'click',
      'notificationId': notificationId,
      'userId': userId,
      'type': data['type'] ?? 'unknown',
      'groupId': groupId ?? 'unknown',
      'source': 'system_tray',
    });
  }

  // Handle tap from Local Notification (RichNotificationService)
  void _handleNotificationTap(Map<String, dynamic> payload) {
    final notificationId = payload['notificationId'];
    final trackingData = payload['trackingData'];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    _firestoreService.logNotificationEvent({
      'event': 'click',
      'notificationId': notificationId,
      'userId': userId,
      'trackingData': trackingData,
      'source': 'local_notification',
    });
  }

  Future<void> _trackEvent(String event, NotificationModel notification) async {
    await _firestoreService.logNotificationEvent({
      'event': event,
      'notificationId': notification.id,
      'userId': notification.userId,
      'type': notification.type,
      'trackingData': notification.trackingData,
    });
  }

  NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'event': return NotificationType.event;
      case 'rating': return NotificationType.rating;
      default: return NotificationType.system;
    }
  }
}
