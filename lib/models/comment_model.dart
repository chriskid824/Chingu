import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String momentId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'momentId': momentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      momentId: map['momentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        momentId,
        userId,
        userName,
        userAvatar,
        content,
        createdAt,
      ];
}
