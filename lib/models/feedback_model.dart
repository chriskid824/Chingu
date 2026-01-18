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
  final String userEmail;
  final FeedbackType type;
  final String description;
  final List<String> imageUrls;
  final FeedbackStatus status;
  final DateTime createdAt;
  final String? deviceInfo; // Optional: Device info for bug reports
  final String? appVersion; // Optional: App version

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.description,
    this.imageUrls = const [],
    this.status = FeedbackStatus.pending,
    required this.createdAt,
    this.deviceInfo,
    this.appVersion,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'other'),
        orElse: () => FeedbackType.other,
      ),
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => FeedbackStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deviceInfo: map['deviceInfo'],
      appVersion: map['appVersion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type.name,
      'description': description,
      'imageUrls': imageUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  // Helper method to get localized string for type
  String getTypeDisplayString() {
    switch (type) {
      case FeedbackType.suggestion:
        return '建議';
      case FeedbackType.bug:
        return '問題回報';
      case FeedbackType.other:
        return '其他';
    }
  }
}
