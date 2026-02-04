import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class UserMomentsScreen extends StatefulWidget {
  final String? userId; // Optional, if null uses current user

  const UserMomentsScreen({super.key, this.userId});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  late final MomentService _momentService;
  late Stream<List<MomentModel>> _momentsStream;
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _momentService = MomentService();
    // Defer accessing context until build or use dependency injection if needed.
    // However, we need userId.
    // Since we depend on AuthProvider for current user ID if widget.userId is null,
    // we should initialize stream in didChangeDependencies or just before usage.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    _targetUserId = widget.userId ?? currentUserId;

    if (_targetUserId != null) {
      _momentsStream = _momentService.getUserMoments(_targetUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check current user for FAB logic
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    final isCurrentUser = _targetUserId == currentUserId;

    if (_targetUserId == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
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
        stream: _momentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final moments = snapshot.data ?? [];

          if (moments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    isCurrentUser ? '分享你的第一個動態吧！' : '暫無動態',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: moments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final moment = moments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: moment.userAvatar != null
                                ? CachedNetworkImageProvider(moment.userAvatar!)
                                : null,
                            child: moment.userAvatar == null
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
                          if (isCurrentUser)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => _showDeleteDialog(context, _momentService, moment.id),
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
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MomentService service, String momentId) {
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.deleteMoment(momentId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('刪除失敗: $e')),
                  );
                }
              }
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
