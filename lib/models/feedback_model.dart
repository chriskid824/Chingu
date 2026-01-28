import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String type; // 'suggestion', 'bug', 'other'
  final String content;
  final String? contactEmail;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? appVersion;
  final String? platform;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.contactEmail,
    required this.createdAt,
    this.status = 'pending',
    this.appVersion,
    this.platform,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'content': content,
      'contactEmail': contactEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'other',
      content: map['content'] ?? '',
      contactEmail: map['contactEmail'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      appVersion: map['appVersion'],
      platform: map['platform'],
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel.fromMap(data, doc.id);
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    String? contactEmail,
    DateTime? createdAt,
    String? status,
    String? appVersion,
    String? platform,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
    );
  }
}
