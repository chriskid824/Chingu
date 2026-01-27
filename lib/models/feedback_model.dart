import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String type; // 'suggestion', 'bug_report', 'other'
  final String content;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  FeedbackModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'other',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    DateTime? createdAt,
    String? status,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
