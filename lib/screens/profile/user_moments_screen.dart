import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/moment_provider.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/core/theme/app_theme.dart';

class UserMomentsScreen extends StatefulWidget {
  const UserMomentsScreen({super.key});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<MomentProvider>().fetchUserMoments(
              user.uid,
              currentUserId: user.uid,
            );
      }
    });
  }

  void _showCreateMomentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateMomentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
        centerTitle: true,
      ),
      body: Consumer2<AuthProvider, MomentProvider>(
        builder: (context, authProvider, momentProvider, child) {
          if (authProvider.userModel == null) {
            return const Center(child: Text('請先登入'));
          }

          if (momentProvider.isLoading && momentProvider.moments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (momentProvider.moments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無動態',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '分享你的第一則動態吧！',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await momentProvider.fetchUserMoments(
                authProvider.userModel!.uid,
                currentUserId: authProvider.userModel!.uid,
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: momentProvider.moments.length,
              itemBuilder: (context, index) {
                final moment = momentProvider.moments[index];
                return MomentCard(
                  moment: moment,
                  onLikeChanged: (_) {
                    momentProvider.toggleLike(moment.id, authProvider.userModel!.uid);
                  },
                  onCommentTap: () {
                    // TODO: Show comments
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMomentSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('發佈動態'),
      ),
    );
  }
}

class _CreateMomentSheet extends StatefulWidget {
  const _CreateMomentSheet();

  @override
  State<_CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<_CreateMomentSheet> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isPosting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user == null) return;

      final success = await context.read<MomentProvider>().createMoment(
            userId: user.uid,
            userName: user.name,
            userAvatar: user.avatarUrl,
            content: _contentController.text.trim(),
            imageFile: _selectedImage,
          );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('發佈成功！')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                Text(
                  '新動態',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _isPosting ? null : _submit,
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('發佈'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '在想什麼呢？',
                border: InputBorder.none,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 14,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image, color: theme.colorScheme.primary),
                  tooltip: '選擇圖片',
                ),
                IconButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                  tooltip: '拍照',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
