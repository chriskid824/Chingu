import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/core/routes/app_router.dart';

class UserMomentsScreen extends StatelessWidget {
  const UserMomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;
    final momentService = MomentService();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('無法獲取用戶資訊')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: momentService.getUserMomentsStream(user.uid, user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final moments = snapshot.data ?? [];

          if (moments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_frames_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無動態',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '點擊下方按鈕分享你的第一則動態',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return MomentCard(
                moment: moment,
                onLikeChanged: (isLiked) {
                  momentService.toggleLike(moment.id, user.uid);
                },
                onCommentTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('留言功能開發中')),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createMoment);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
