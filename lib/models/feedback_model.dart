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
  final String id;
  final String userId;
  final FeedbackType type;
  final String description;
  final String? contactEmail;
  final DateTime createdAt;
  final FeedbackStatus status;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    this.contactEmail,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'other'),
        orElse: () => FeedbackType.other,
      ),
      description: map['description'] ?? '',
      contactEmail: map['contactEmail'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] ?? 'pending'),
        orElse: () => FeedbackStatus.pending,
      ),
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'description': description,
      'contactEmail': contactEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    FeedbackType? type,
    String? description,
    String? contactEmail,
    DateTime? createdAt,
    FeedbackStatus? status,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
