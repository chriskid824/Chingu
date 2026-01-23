import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  problem,
  other,
}

class FeedbackModel {
  final String? id;
  final String userId;
  final FeedbackType type;
  final String content;
  final DateTime createdAt;
  final String status; // 'open', 'reviewed', 'resolved'

  FeedbackModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'open',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name, // using .name is cleaner in newer Dart
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => FeedbackType.other,
      ),
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'open',
    );
  }

  // Helper for UI display
  String get typeDisplay {
    switch (type) {
      case FeedbackType.suggestion:
        return '建議';
      case FeedbackType.problem:
        return '問題回報';
      case FeedbackType.other:
        return '其他';
    }
  }
}
