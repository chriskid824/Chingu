import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String type; // 'suggestion', 'bug', 'other'
  final String content;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String platform; // 'android', 'ios', 'web'
  final String? appVersion;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'pending',
    required this.platform,
    this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'platform': platform,
      'appVersion': appVersion,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      type: map['type'] ?? 'other',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      platform: map['platform'] ?? 'unknown',
      appVersion: map['appVersion'],
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    return FeedbackModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
