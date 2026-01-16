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
  final String content;
  final DateTime createdAt;
  final String? contactEmail;
  final FeedbackStatus status;
  final String? appVersion;
  final Map<String, dynamic>? deviceInfo;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.contactEmail,
    this.status = FeedbackStatus.pending,
    this.appVersion,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'contactEmail': contactEmail,
      'status': status.name,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
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
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      contactEmail: map['contactEmail'],
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      appVersion: map['appVersion'],
      deviceInfo: map['deviceInfo'],
    );
  }
}
