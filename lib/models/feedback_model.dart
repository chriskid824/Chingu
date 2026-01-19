import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  bug,
  inquiry,
  other,
}

extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.suggestion:
        return '建議';
      case FeedbackType.bug:
        return '問題回報';
      case FeedbackType.inquiry:
        return '詢問';
      case FeedbackType.other:
        return '其他';
    }
  }
}

class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final FeedbackType type;
  final String content;
  final DateTime createdAt;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String? contactEmail;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'open',
    this.contactEmail,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel.fromMap(data, doc.id);
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      type: _parseType(map['type']),
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'open',
      contactEmail: map['contactEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type.name,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'contactEmail': contactEmail,
    };
  }

  static FeedbackType _parseType(String? type) {
    switch (type) {
      case 'suggestion':
        return FeedbackType.suggestion;
      case 'bug':
        return FeedbackType.bug;
      case 'inquiry':
        return FeedbackType.inquiry;
      default:
        return FeedbackType.other;
    }
  }
}
