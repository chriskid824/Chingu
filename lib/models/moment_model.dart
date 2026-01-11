import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bool isBookmarked;

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
    this.isBookmarked = false,
  });

  factory MomentModel.fromMap(Map<String, dynamic> map, String id) {
    return MomentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isBookmarked: map['isBookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
    };
  }

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
    bool? isBookmarked,
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
      isBookmarked: isBookmarked ?? this.isBookmarked,
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
        isBookmarked,
      ];
}
