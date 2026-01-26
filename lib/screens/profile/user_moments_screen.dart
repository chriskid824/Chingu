import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:image_picker/image_picker.dart';

class UserMomentsScreen extends StatefulWidget {
  const UserMomentsScreen({super.key});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final MomentService _momentService = MomentService();

  void _showCreateMomentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CreateMomentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('無法載入用戶資訊'))
          : StreamBuilder<List<MomentModel>>(
              stream: _momentService.getMoments(user.uid),
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
                        Text('還沒有發布過動態', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: moments.length,
                  itemBuilder: (context, index) {
                    final moment = moments[index];
                    return MomentCard(
                      moment: moment,
                      onLikeChanged: (isLiked) {
                        // TODO: Implement like logic
                      },
                      onCommentTap: () {
                        // TODO: Implement comment logic
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMomentModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateMomentSheet extends StatefulWidget {
  const CreateMomentSheet({super.key});

  @override
  State<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<CreateMomentSheet> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isPosting = false;
  final MomentService _momentService = MomentService();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _postMoment() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _imageFile == null) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) throw Exception('User not logged in');

      await _momentService.createMoment(
        userId: user.uid,
        userName: user.name,
        userAvatar: user.avatarUrl,
        content: content,
        imageFile: _imageFile,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('發布成功')),
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
          _isPosting = false;
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
              hintText: '分享你的生活...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_imageFile != null)
            Stack(
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, size: 28),
                color: Theme.of(context).primaryColor,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isPosting ? null : _postMoment,
                child: _isPosting
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
