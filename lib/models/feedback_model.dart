import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  bug,
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
  final String title;
  final String description;
  final String? contactEmail;
  final List<String> images;
  final DateTime createdAt;
  final FeedbackStatus status;
  final String? appVersion;
  final String? deviceInfo;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.contactEmail,
    this.images = const [],
    required this.createdAt,
    this.status = FeedbackStatus.pending,
    this.appVersion,
    this.deviceInfo,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel.fromMap(data, doc.id);
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => FeedbackType.other,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      contactEmail: map['contactEmail'],
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => FeedbackStatus.pending,
      ),
      appVersion: map['appVersion'],
      deviceInfo: map['deviceInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'contactEmail': contactEmail,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
    };
  }
}
