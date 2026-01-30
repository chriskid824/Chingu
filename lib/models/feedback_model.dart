import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String type; // 'suggestion' or 'bug'
  final String content;
  final String? contactInfo;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.contactInfo,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'content': content,
      'contactInfo': contactInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'suggestion',
      content: map['content'] ?? '',
      contactInfo: map['contactInfo'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}
