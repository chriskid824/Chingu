import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  match,
  message,
  event,
  system,
  rating,
  unknown;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.unknown,
    );
  }
}

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type; // 'match', 'event', 'message', 'rating', 'system'
  final String title;
  final String message;
  final String? imageUrl;
  final String? actionType; // 'navigate', 'open_event', 'open_chat', etc.
  final String? actionData; // JSON string or ID
  final String? deeplink;
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
      type: NotificationType.fromString(map['type']),
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
    return copyWith(isRead: true);
  }

  /// 複製對象
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? imageUrl,
    String? actionType,
    String? actionData,
    String? deeplink,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      deeplink: deeplink ?? this.deeplink,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
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
