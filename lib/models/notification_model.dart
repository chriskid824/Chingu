import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知類型枚舉
enum NotificationType {
  match,
  event,
  message,
  rating,
  system,
  unknown,
}

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type; // 'match', 'event', 'message', 'rating', 'system'
  final String title;
  final String message; // Content
  final String? imageUrl;
  final String? actionType; // 'navigate', 'open_event', 'open_chat', etc.
  final String? actionData; // JSON string or ID
  final String? deeplink; // Deep link for navigation
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionType,
    this.actionData,
    this.deeplink,
    this.isRead = false,
    required this.createdAt,
  });

  /// 從 Firestore 文檔創建 NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 NotificationModel
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: _parseNotificationType(map['type']),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      actionType: map['actionType'],
      actionData: map['actionData'],
      deeplink: map['deeplink'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionData': actionData,
      'deeplink': deeplink,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 複製並標記為已讀
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      deeplink: deeplink,
      isRead: true,
      createdAt: createdAt,
    );
  }

  /// 輔助方法：解析通知類型
  static NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.system;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NotificationType.unknown,
      );
    } catch (_) {
      return NotificationType.unknown;
    }
  }

  /// 獲取通知圖標
  String get iconName {
    switch (type) {
      case NotificationType.match:
        return 'favorite';
      case NotificationType.event:
        return 'event';
      case NotificationType.message:
        return 'message';
      case NotificationType.rating:
        return 'star';
      case NotificationType.system:
      default:
        return 'notifications';
    }
  }
}
