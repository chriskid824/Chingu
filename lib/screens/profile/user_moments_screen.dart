import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/moment_service.dart';
import '../../models/moment_model.dart';
import '../../core/routes/app_router.dart';
import 'package:intl/intl.dart';

class UserMomentsScreen extends StatelessWidget {
  const UserMomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人動態'),
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: MomentService().getMoments(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final moments = snapshot.data ?? [];
          if (moments.isEmpty) {
            return const Center(child: Text('還沒有任何動態，快去發布吧！'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: moment.userAvatar != null
                                ? CachedNetworkImageProvider(moment.userAvatar!)
                                : null,
                            child: moment.userAvatar == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(moment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(moment.createdAt),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                           if (moment.userId == user.uid)
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                _showOptions(context, moment);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (moment.textContent != null && moment.textContent!.isNotEmpty)
                        Text(moment.textContent!),
                      if (moment.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildImageGrid(moment.imageUrls),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${moment.likeCount}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
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

  void _showOptions(BuildContext context, MomentModel moment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('刪除動態', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // Show confirmation
                  final confirm = await showDialog<bool>(
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
                          child: const Text('刪除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                     await MomentService().deleteMoment(moment.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrls[0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: imageUrls.length == 2 ? 2 : 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
