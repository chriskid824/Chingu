import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? textContent;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likeCount;

  MomentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.textContent,
    required this.imageUrls,
    required this.createdAt,
    this.likeCount = 0,
  });

  factory MomentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MomentModel.fromMap(data, doc.id);
  }

  factory MomentModel.fromMap(Map<String, dynamic> map, String id) {
    return MomentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      userAvatar: map['userAvatar'],
      textContent: map['textContent'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likeCount: map['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'textContent': textContent,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
    };
  }
}
