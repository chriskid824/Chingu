import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MomentModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const MomentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  MomentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return MomentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
      // isLiked is local state, usually not saved to global moment doc,
      // but maybe needed if we save it per user.
      // For now, I'll exclude it or include it as false.
      // Actually, 'isLiked' depends on who is viewing it.
      // So when saving to Firestore, we usually don't save 'isLiked'.
      // But for simplicity of this model being used elsewhere, I won't save it.
    };
  }

  factory MomentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    // Handle Timestamp
    DateTime createdAtDate;
    if (map['createdAt'] is Timestamp) {
      createdAtDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      // Fallback or legacy
      createdAtDate = DateTime.parse(map['createdAt']);
    } else {
      createdAtDate = DateTime.now();
    }

    return MomentModel(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: createdAtDate,
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatar,
        content,
        imageUrl,
        createdAt,
        likeCount,
        commentCount,
        isLiked,
      ];
}
