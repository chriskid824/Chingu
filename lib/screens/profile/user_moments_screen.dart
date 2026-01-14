import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class UserMomentsScreen extends StatefulWidget {
  const UserMomentsScreen({super.key});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: _firestoreService.getUserMomentsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final moments = snapshot.data ?? [];

          if (moments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('還沒有發布動態', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return _buildMomentCard(moment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMomentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMomentCard(MomentModel moment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: moment.userAvatar != null
                      ? CachedNetworkImageProvider(
                          moment.userAvatar!,
                          cacheManager: ImageCacheManager().manager,
                        )
                      : null,
                  child: moment.userAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDate(moment.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(moment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('刪除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (moment.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(moment.content),
            ),
          if (moment.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CachedNetworkImage(
                imageUrl: moment.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheManager: ImageCacheManager().manager,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDelete(String momentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除動態'),
        content: const Text('確定要刪除這則動態嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteMoment(momentId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('動態已刪除')),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  void _showCreateMomentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateMomentSheet(),
    );
  }
}

class CreateMomentSheet extends StatefulWidget {
  const CreateMomentSheet({super.key});

  @override
  State<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<CreateMomentSheet> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇圖片失敗: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _imageFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) throw Exception('用戶未登入');

      String? imageUrl;
      if (_imageFile != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = _imageFile!.path.split('.').last;
        final path = 'moments/${user.uid}/$timestamp.$extension';

        final task = _storageService.uploadFile(_imageFile!, path);
        await task;
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final moment = MomentModel(
        id: '', // Firestore will generate ID
        userId: user.uid,
        userName: user.name,
        userAvatar: user.avatarUrl,
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createMoment(moment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動態發布成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發布失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              const Text(
                '發布動態',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '分享你的心情...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_imageFile != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                    });
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, size: 32, color: Colors.blue),
                tooltip: '選擇圖片',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
