import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  suggestion,
  bug,
  other,
}

class FeedbackModel {
  final String id;
  final String userId;
  final FeedbackType type;
  final String description;
  final String contactEmail;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final List<String> imageUrls;
  final String? version; // App version
  final String? platform; // iOS, Android

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.contactEmail,
    required this.createdAt,
    this.status = 'pending',
    this.imageUrls = const [],
    this.version,
    this.platform,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'description': description,
      'contactEmail': contactEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'imageUrls': imageUrls,
      'version': version,
      'platform': platform,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => FeedbackType.other,
      ),
      description: map['description'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      version: map['version'],
      platform: map['platform'],
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    FeedbackType? type,
    String? description,
    String? contactEmail,
    DateTime? createdAt,
    String? status,
    List<String>? imageUrls,
    String? version,
    String? platform,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      version: version ?? this.version,
      platform: platform ?? this.platform,
    );
  }
}
