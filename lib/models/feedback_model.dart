import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  bug,
  other,
}

extension FeedbackTypeExtension on FeedbackType {
  String get label {
    switch (this) {
      case FeedbackType.suggestion:
        return '功能建議';
      case FeedbackType.bug:
        return '問題回報';
      case FeedbackType.other:
        return '其他';
    }
  }
}

class FeedbackModel {
  final String? id;
  final String userId;
  final FeedbackType type;
  final String description;
  final String? contactEmail;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  FeedbackModel({
    this.id,
    required this.userId,
    required this.type,
    required this.description,
    this.contactEmail,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'description': description,
      'contactEmail': contactEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeedbackType.other,
      ),
      description: map['description'] ?? '',
      contactEmail: map['contactEmail'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}
