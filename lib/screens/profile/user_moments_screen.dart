import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/moment_model.dart';
import '../../services/moment_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/image_cache_manager.dart';

class UserMomentsScreen extends StatefulWidget {
  final String userId; // The user whose moments we are viewing
  final String? userName; // Optional, for header if needed

  const UserMomentsScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final MomentService _momentService = MomentService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid;
    final isCurrentUser = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? '我的動態' : (widget.userName != null ? '${widget.userName}的動態' : '用戶動態')),
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: _momentService.getMomentsStream(widget.userId, currentUserId ?? ''),
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
                  const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(isCurrentUser ? '你還沒有發布任何動態' : '該用戶暫無動態'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: moments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final moment = moments[index];
              return _MomentCard(
                moment: moment,
                isCurrentUser: isCurrentUser,
                onLike: () => _momentService.toggleLike(moment.id, currentUserId!),
                onDelete: () => _momentService.deleteMoment(moment.id),
              );
            },
          );
        },
      ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(
              onPressed: () => _showAddMomentSheet(context, currentUserId!, authProvider.userModel!.name, authProvider.userModel!.avatarUrl),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddMomentSheet(BuildContext context, String userId, String userName, String? userAvatar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddMomentSheet(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        momentService: _momentService,
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final MomentModel moment;
  final bool isCurrentUser;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _MomentCard({
    required this.moment,
    required this.isCurrentUser,
    required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: moment.userAvatar != null
                  ? CachedNetworkImageProvider(
                      moment.userAvatar!,
                      cacheManager: ImageCacheManager().manager,
                    )
                  : null,
              child: moment.userAvatar == null ? const Icon(Icons.person) : null,
            ),
            title: Text(moment.userName),
            subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(moment.createdAt)),
            trailing: isCurrentUser
                ? IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('刪除', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(ctx);
                                _confirmDelete(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : null,
          ),
          if (moment.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(moment.content, style: const TextStyle(fontSize: 16)),
            ),
          if (moment.imageUrl != null)
            CachedNetworkImage(
              imageUrl: moment.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              cacheManager: ImageCacheManager().manager,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    moment.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: moment.isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: onLike,
                ),
                Text('${moment.likeCount}'),
                // Comments not implemented yet
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除這條動態嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddMomentSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;
  final MomentService momentService;

  const AddMomentSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.momentService,
  });

  @override
  State<AddMomentSheet> createState() => _AddMomentSheetState();
}

class _AddMomentSheetState extends State<AddMomentSheet> {
  final _textController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _postMoment() async {
    if (_textController.text.trim().isEmpty && _imageFile == null) return;

    setState(() => _isUploading = true);
    try {
      await widget.momentService.createMoment(
        userId: widget.userId,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        content: _textController.text.trim(),
        imageFile: _imageFile,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發布失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('發布動態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '分享你的生活...',
              border: InputBorder.none,
            ),
          ),
          if (_imageFile != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _imageFile = null),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Colors.green),
                onPressed: _pickImage,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isUploading ? null : _postMoment,
                child: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('發布'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
