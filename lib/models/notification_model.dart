import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'match', 'event', 'message', 'rating', 'system'
  final String title;
  final String content;
  final String? imageUrl;
  final String? actionType; // 'navigate', 'open_event', 'open_chat', etc.
  final String? actionData; // JSON string or ID
  final String? deeplink;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
    this.actionType,
    this.actionData,
    this.deeplink,
    this.isRead = false,
    required this.timestamp,
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
      type: map['type'] ?? 'system',
      title: map['title'] ?? '',
      content: map['content'] ?? map['message'] ?? '',
      imageUrl: map['imageUrl'],
      actionType: map['actionType'],
      actionData: map['actionData'],
      deeplink: map['deeplink'],
      isRead: map['isRead'] ?? false,
      timestamp: ((map['timestamp'] ?? map['createdAt'] ?? Timestamp.now()) as Timestamp).toDate(),
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': content, // Keep as message for DB compatibility
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionData': actionData,
      'deeplink': deeplink,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(timestamp), // Keep as createdAt for DB compatibility
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
      actionType: actionType,
      actionData: actionData,
      deeplink: deeplink,
      isRead: true,
      timestamp: timestamp,
    );
  }

  /// 獲取通知圖標
  String get iconName {
    switch (type) {
      case 'match':
        return 'favorite';
      case 'event':
        return 'event';
      case 'message':
        return 'message';
      case 'rating':
        return 'star';
      case 'system':
      default:
        return 'notifications';
    }
  }
}
