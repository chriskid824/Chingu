import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/moment_provider.dart';
import '../../models/moment_model.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';

class UserMomentsScreen extends StatelessWidget {
  const UserMomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用戶動態'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createMoment);
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<MomentProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<MomentModel>>(
            stream: provider.momentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('載入失敗: ${snapshot.error}'));
              }

              final moments = snapshot.data ?? [];

              if (moments.isEmpty) {
                return const Center(child: Text('還沒有動態，快來分享吧！'));
              }

              return ListView.builder(
                itemCount: moments.length,
                itemBuilder: (context, index) {
                  final moment = moments[index];
                  return _MomentCard(moment: moment);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final MomentModel moment;

  const _MomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().userModel;
    final isAuthor = currentUser?.uid == moment.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: moment.userAvatarUrl != null
                      ? CachedNetworkImageProvider(moment.userAvatarUrl!)
                      : null,
                  child: moment.userAvatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(moment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                    IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, moment),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            if (moment.content.isNotEmpty)
              Text(
                moment.content,
                style: const TextStyle(fontSize: 15),
              ),
            if (moment.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: moment.imageUrl!,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MomentModel moment) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('刪除動態'),
              content: const Text('確定要刪除這則動態嗎？'),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                  ),
                  TextButton(
                      onPressed: () {
                          context.read<MomentProvider>().deleteMoment(moment.id, moment.imageUrl);
                          Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('刪除'),
                  ),
              ],
          ),
      );
  }
}
