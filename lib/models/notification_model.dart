import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  /// 類型: 'match', 'message', 'event', 'rating', 'system'
  final String type;
  final String title;
  /// 內容 (映射到 message 欄位)
  final String message;
  final String? imageUrl;
  final String? actionType; // 'navigate', 'open_event', 'open_chat', etc.
  final String? actionData; // JSON string or ID
  final bool isRead;
  final DateTime createdAt;
  /// Deep link 路由
  final String? deeplink;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionType,
    this.actionData,
    this.isRead = false,
    required this.createdAt,
    this.deeplink,
  });

  /// 獲取內容 (message 別名)
  String get content => message;

  /// 獲取時間戳 (createdAt 別名)
  DateTime get timestamp => createdAt;

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
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      actionType: map['actionType'],
      actionData: map['actionData'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deeplink: map['deeplink'],
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionData': actionData,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'deeplink': deeplink,
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
      isRead: true,
      createdAt: createdAt,
      deeplink: deeplink,
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
