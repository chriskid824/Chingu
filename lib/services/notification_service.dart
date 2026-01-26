import 'analytics_service.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final RichNotificationService _richService = RichNotificationService();
  final NotificationABService _abService = NotificationABService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _richService.initialize();

    // Set up click listener for tracking
    _richService.setOnNotificationTap((data) {
      _trackNotificationClick(data);
    });

    _isInitialized = true;
  }

  /// Sends a local notification with A/B testing content and tracking
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    // 1. Get A/B content
    final content = _abService.getContent(userId, type, params: params);
    final group = _abService.getGroup(userId);
    final groupName = group.toString().split('.').last;
    final typeName = type.toString().split('.').last;

    // 2. Track Send
    await _analytics.logEvent(
      name: 'notification_send',
      parameters: {
        'userId': userId,
        'type': typeName,
        'group': groupName,
      },
    );

    // 3. Construct NotificationModel
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final model = NotificationModel(
      id: id,
      userId: userId,
      type: typeName,
      title: content.title,
      message: content.body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
    );

    // 4. Show notification with tracking payload
    final trackingPayload = {
      'tracking_type': typeName,
      'tracking_group': groupName,
      'userId': userId,
    };

    await _richService.showNotification(model, additionalPayload: trackingPayload);
  }

  void _trackNotificationClick(Map<String, dynamic> data) {
    final type = data['tracking_type'];
    final group = data['tracking_group'];
    final userId = data['userId'];
    final actionId = data['actionId'];

    // Only log if tracking info is present
    if (type != null && group != null) {
      _analytics.logEvent(
        name: 'notification_click',
        parameters: {
          'userId': userId ?? 'unknown',
          'type': type,
          'group': group,
          if (actionId != null) 'actionId': actionId,
        },
      );
    }
  }
}
