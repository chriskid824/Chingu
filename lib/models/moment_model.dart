import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likeCount;

  MomentModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    this.likeCount = 0,
  });

  /// Factory method to create a MomentModel from a Firestore DocumentSnapshot
  factory MomentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MomentModel.fromMap(data, doc.id);
  }

  /// Factory method to create a MomentModel from a Map
  factory MomentModel.fromMap(Map<String, dynamic> map, String id) {
    return MomentModel(
      id: id,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likeCount: map['likeCount'] ?? 0,
    );
  }

  /// Converts the MomentModel instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
    };
  }

  MomentModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? likeCount,
  }) {
    return MomentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
