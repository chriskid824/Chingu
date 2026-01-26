import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  match,
  message,
  event,
  system,
  rating,
}

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final String? imageUrl;
  final String? deeplink;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
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
      type: _parseType(map['type']),
      title: map['title'] ?? '',
      content: map['content'] ?? map['message'] ?? '', // Backward compatibility
      imageUrl: map['imageUrl'],
      deeplink: map['deeplink'] ?? _constructDeeplink(map['actionType'], map['actionData']),
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
      'content': content,
      'message': content, // Keep message for backward compatibility
      'imageUrl': imageUrl,
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
      content: content,
      imageUrl: imageUrl,
      deeplink: deeplink,
      isRead: true,
      createdAt: createdAt,
    );
  }

  /// 獲取通知圖標名稱
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
        return 'notifications';
    }
  }

  static NotificationType _parseType(String? type) {
    if (type == null) return NotificationType.system;
    try {
      return NotificationType.values.firstWhere((e) => e.name == type);
    } catch (_) {
      // Fallback for old string values if they differ or just in case
      return NotificationType.system;
    }
  }

  static String? _constructDeeplink(String? actionType, String? actionData) {
    if (actionType == null) return null;
    if (actionType == 'open_chat' && actionData != null) {
        return 'app://chingu/chat-detail?userId=$actionData';
    }
    if (actionType == 'view_event' && actionData != null) {
        return 'app://chingu/event-detail?eventId=$actionData';
    }
    return null;
  }
}
