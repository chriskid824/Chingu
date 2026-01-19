import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知模型
class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'match', 'event', 'message', 'rating', 'system'
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? deeplink;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.deeplink,
    this.imageUrl,
  });

  /// 從 Firestore 文檔創建 NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 NotificationModel
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle timestamp compatibility
    final timestampVal = map['timestamp'] ?? map['createdAt'];
    DateTime timestamp;
    if (timestampVal is Timestamp) {
      timestamp = timestampVal.toDate();
    } else if (timestampVal is String) {
       // Just in case it's a string in some contexts (e.g. JSON)
       timestamp = DateTime.tryParse(timestampVal) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'system',
      title: map['title'] ?? '',
      content: map['content'] ?? map['message'] ?? '',
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      deeplink: map['deeplink'],
      imageUrl: map['imageUrl'],
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'content': content,
      // Save as both timestamp and createdAt to support legacy queries and new model
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'deeplink': deeplink,
      'imageUrl': imageUrl,
      // Also save message for legacy support if needed, but content is new standard
      'message': content,
    };
  }

  /// 複製並修改
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? deeplink,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deeplink: deeplink ?? this.deeplink,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// 複製並標記為已讀
  NotificationModel markAsRead() {
    return copyWith(isRead: true);
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
