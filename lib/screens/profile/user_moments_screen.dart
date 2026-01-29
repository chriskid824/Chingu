import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/moments_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class UserMomentsScreen extends StatelessWidget {
  final String? userId; // If null, use current user

  const UserMomentsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userModel;

    // Determine target userId
    final String targetUserId = userId ?? currentUser?.uid ?? '';

    if (targetUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('動態')),
        body: const Center(child: Text('無法獲取用戶資訊')),
      );
    }

    final bool isCurrentUser = currentUser != null && currentUser.uid == targetUserId;
    final momentsService = MomentsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('動態'),
      ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createMoment);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<MomentModel>>(
        stream: momentsService.getUserMoments(targetUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final moments = snapshot.data ?? [];

          if (moments.isEmpty) {
            return const Center(child: Text('尚無動態'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return _MomentCard(
                moment: moment,
                isCurrentUser: isCurrentUser,
                onDelete: () => _confirmDelete(context, momentsService, moment.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MomentsService service,
    String momentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除動態'),
        content: const Text('確定要刪除這則動態嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.deleteMoment(momentId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }
}

class _MomentCard extends StatelessWidget {
  final MomentModel moment;
  final bool isCurrentUser;
  final VoidCallback onDelete;

  const _MomentCard({
    required this.moment,
    required this.isCurrentUser,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(moment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (moment.content.isNotEmpty) ...[
              Text(
                moment.content,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
            ],
            if (moment.imageUrls.isNotEmpty)
              _buildImageGrid(moment.imageUrls),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: urls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: urls.length == 2 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: urls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}
