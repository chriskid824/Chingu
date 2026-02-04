import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  problem,
  other,
}

class FeedbackModel {
  final String? id;
  final String userId;
  final String type; // 'suggestion', 'problem', 'other'
  final String content;
  final String? contactInfo;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? appVersion;
  final String? platform;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.contactInfo,
    required this.createdAt,
    this.status = 'pending',
    this.appVersion,
    this.platform,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'content': content,
      'contactInfo': contactInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'other',
      content: map['content'] ?? '',
      contactInfo: map['contactInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      appVersion: map['appVersion'],
      platform: map['platform'],
    );
  }

  static String typeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.suggestion:
        return 'suggestion';
      case FeedbackType.problem:
        return 'problem';
      case FeedbackType.other:
        return 'other';
    }
  }
}
