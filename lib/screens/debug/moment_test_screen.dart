import 'package:flutter/material.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/utils/haptic_utils.dart';

class MomentTestScreen extends StatefulWidget {
  const MomentTestScreen({super.key});

  @override
  State<MomentTestScreen> createState() => _MomentTestScreenState();
}

class _MomentTestScreenState extends State<MomentTestScreen> {
  // Mock data
  List<MomentModel> moments = [
    MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Alice',
      content: '剛發現一家超棒的餐廳！大家要一起去嗎？ 🍝',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 5,
      commentCount: 2,
      isLiked: false,
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
    ),
    MomentModel(
      id: '2',
      userId: 'user2',
      userName: 'Bob',
      content: '今天的夕陽真美 🌅',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likeCount: 12,
      commentCount: 0,
      isLiked: true,
    ),
  ];

  void _handleLike(String momentId, bool isLiked) {
    setState(() {
      final index = moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final moment = moments[index];
        moments[index] = moment.copyWith(
          isLiked: isLiked,
          likeCount: moment.likeCount + (isLiked ? 1 : -1),
        );
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLiked ? '已按讚！' : '取消按讚'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleComment(String momentId) {
    HapticUtils.selection();
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('新增評論'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '寫下你的想法...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _addComment(momentId, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('發送'),
            ),
          ],
        );
      },
    );
  }

  void _addComment(String momentId, String content) {
    setState(() {
      final index = moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final moment = moments[index];
        moments[index] = moment.copyWith(
          commentCount: moment.commentCount + 1,
        );
      }
    });

    HapticUtils.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已發送評論: $content'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動態測試 (Moment Card)'),
      ),
      body: ListView.builder(
        itemCount: moments.length,
        itemBuilder: (context, index) {
          final moment = moments[index];
          return MomentCard(
            moment: moment,
            onLikeChanged: (isLiked) => _handleLike(moment.id, isLiked),
            onCommentTap: () => _handleComment(moment.id),
          );
        },
      ),
    );
  }
}
