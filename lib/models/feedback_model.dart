import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String? userEmail;
  final String type; // 'suggestion', 'bug_report', 'other'
  final String content;
  final DateTime createdAt;
  final String status; // 'new', 'in_progress', 'resolved', 'closed'
  final String? appVersion;
  final String? platform;

  FeedbackModel({
    this.id,
    required this.userId,
    this.userEmail,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'new',
    this.appVersion,
    this.platform,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      type: map['type'] ?? 'other',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'new',
      appVersion: map['appVersion'],
      platform: map['platform'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'appVersion': appVersion,
      'platform': platform,
    };
  }
}
