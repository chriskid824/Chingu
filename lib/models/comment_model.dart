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

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      momentId: map['momentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt,
    };
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
