import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;

  MomentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
  });

  factory MomentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MomentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
    };
  }
}
