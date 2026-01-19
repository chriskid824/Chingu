import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  match,
  message,
  event,
  system,
}

/// Notification Model
/// Contains type (match/message/event), title, content, timestamp, read status, deeplink route
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? route;
  final String? imageUrl; // Kept for UI compatibility

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.route,
    this.imageUrl,
  });

  /// Create NotificationModel from Firestore DocumentSnapshot
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  /// Create NotificationModel from Map
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: _parseType(map['type']),
      title: map['title'] ?? '',
      content: map['content'] ?? map['message'] ?? '', // Fallback for migration
      timestamp: (map['timestamp'] ?? map['createdAt'] ?? Timestamp.now()) is Timestamp
          ? (map['timestamp'] ?? map['createdAt']).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      route: map['route'] ?? map['deeplink'],
      imageUrl: map['imageUrl'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'route': route,
      'imageUrl': imageUrl,
    };
  }

  /// Copy and mark as read
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      content: content,
      timestamp: timestamp,
      isRead: true,
      route: route,
      imageUrl: imageUrl,
    );
  }

  static NotificationType _parseType(String? typeStr) {
    if (typeStr == null) return NotificationType.system;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.system,
      );
    } catch (_) {
      return NotificationType.system;
    }
  }

  /// Helper for UI icons
  String get iconName {
    switch (type) {
      case NotificationType.match:
        return 'favorite';
      case NotificationType.event:
        return 'event';
      case NotificationType.message:
        return 'message';
      case NotificationType.system:
      default:
        return 'notifications';
    }
  }
}
