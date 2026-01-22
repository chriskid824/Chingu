import 'package:equatable/equatable.dart';

/// Model representing a user moment (dynamic post)
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
