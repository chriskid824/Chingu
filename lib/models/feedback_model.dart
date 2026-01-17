import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  problem,
  other,
}

enum FeedbackStatus {
  pending,
  reviewed,
  resolved,
}

class FeedbackModel {
  final String? id;
  final String? userId;
  final FeedbackType type;
  final String content;
  final String? contactEmail;
  final FeedbackStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? deviceInfo; // Optional: for problem reports

  FeedbackModel({
    this.id,
    this.userId,
    required this.type,
    required this.content,
    this.contactEmail,
    this.status = FeedbackStatus.pending,
    required this.createdAt,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'content': content,
      'contactEmail': contactEmail,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'deviceInfo': deviceInfo,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'],
      type: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => FeedbackType.other,
      ),
      content: map['content'] ?? '',
      contactEmail: map['contactEmail'],
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deviceInfo: map['deviceInfo'],
    );
  }
}
