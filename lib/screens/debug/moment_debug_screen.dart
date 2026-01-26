import 'package:flutter/material.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/widgets/moment_card.dart';

class MomentDebugScreen extends StatefulWidget {
  const MomentDebugScreen({super.key});

  @override
  State<MomentDebugScreen> createState() => _MomentDebugScreenState();
}

class _MomentDebugScreenState extends State<MomentDebugScreen> {
  final List<MomentModel> _moments = [
    MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Alice',
      content: '今天的天氣真好！去公園散步很舒服。 ☀️',
      imageUrl: 'https://picsum.photos/id/1015/600/400',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 5,
      commentCount: 1,
      isLiked: false,
      comments: [
        CommentModel(
          id: 'c1',
          userId: 'user2',
          userName: 'Bob',
          content: '看起來很棒！',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),
    MomentModel(
      id: '2',
      userId: 'user3',
      userName: 'Charlie',
      content: '剛剛吃了一頓美味的晚餐！ 🍜',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      likeCount: 12,
      commentCount: 0,
      isLiked: true,
      comments: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動態功能測試'),
      ),
      body: ListView.builder(
        itemCount: _moments.length,
        itemBuilder: (context, index) {
          final moment = _moments[index];
          return MomentCard(
            moment: moment,
            onLikeChanged: (isLiked) {
              setState(() {
                _moments[index] = moment.copyWith(
                  isLiked: isLiked,
                  likeCount: moment.likeCount + (isLiked ? 1 : -1),
                );
              });
            },
            onAddComment: (text) {
              print('New comment on Moment ${index + 1}: $text');
              final newComment = CommentModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user',
                userName: '我',
                content: text,
                createdAt: DateTime.now(),
              );

              setState(() {
                _moments[index] = moment.copyWith(
                  comments: [...moment.comments, newComment],
                  commentCount: moment.commentCount + 1,
                );
              });
            },
          );
        },
      ),
    );
  }
}
