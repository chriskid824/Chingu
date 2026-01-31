import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String type; // 'suggestion', 'bug', 'other'
  final String title;
  final String description;
  final String? imageUrl;
  final String status; // 'open', 'closed', 'in_progress'
  final DateTime createdAt;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.status = 'open',
    required this.createdAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      type: map['type'] ?? 'other',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
