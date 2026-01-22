import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String category; // 'suggestion', 'bug', 'other'
  final String content;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? platform; // 'ios', 'android', 'web'

  FeedbackModel({
    this.id,
    required this.userId,
    required this.category,
    required this.content,
    required this.createdAt,
    this.status = 'pending',
    this.platform,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'other',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      platform: map['platform'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'platform': platform,
    };
  }
}
