import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/widgets/loading_dialog.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/utils/haptic_utils.dart';

class UserMomentsScreen extends StatefulWidget {
  final String? userId; // 如果為 null，則顯示當前用戶的動態

  const UserMomentsScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<MomentModel> _moments = [];
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _loadMoments();
  }

  void _checkCurrentUser() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.uid;

    if (widget.userId == null || widget.userId == currentUserId) {
      _isCurrentUser = true;
    }
  }

  Future<void> _loadMoments() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      final targetUserId = widget.userId ?? authProvider.uid;

      if (targetUserId == null) {
        // Should not happen if auth is required
        setState(() => _isLoading = false);
        return;
      }

      final moments = await _firestoreService.getMoments(targetUserId);

      if (mounted) {
        setState(() {
          _moments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加載失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showCreateMomentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateMomentSheet(),
    ).then((created) {
      if (created == true) {
        _loadMoments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('動態牆', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _moments.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.photo_library_outlined,
                    title: '還沒有動態',
                    message: _isCurrentUser ? '發布第一條動態與大家分享吧！' : '該用戶尚未發布任何動態',
                    actionText: _isCurrentUser ? '發布動態' : null,
                    onActionPressed: _isCurrentUser ? _showCreateMomentDialog : null,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMoments,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _moments.length,
                    itemBuilder: (context, index) {
                      return MomentCard(
                        moment: _moments[index],
                        onLikeChanged: (isLiked) {
                          // TODO: Implement actual like logic in backend
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: _isCurrentUser
          ? FloatingActionButton(
              onPressed: () {
                HapticUtils.selection();
                _showCreateMomentDialog();
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _CreateMomentSheet extends StatefulWidget {
  const _CreateMomentSheet();

  @override
  State<_CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<_CreateMomentSheet> {
  final _textController = TextEditingController();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticUtils.selection();
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
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

  Future<void> _submitMoment() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    HapticUtils.medium();

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String? imageUrl;

      // 1. Upload image if selected
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'user_moments/${currentUser.uid}/$timestamp.jpg';
        final task = _storageService.uploadFile(_selectedImage!, path);

        await task;
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      // 2. Create moment
      final newMoment = MomentModel(
        id: '', // Will be ignored/generated by FirestoreService
        userId: currentUser.uid,
        userName: currentUser.name,
        userAvatar: currentUser.profileImages.isNotEmpty ? currentUser.profileImages.first : null,
        content: _textController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        likeCount: 0,
        commentCount: 0,
      );

      await _firestoreService.createMoment(newMoment);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發布失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '發布動態',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '分享你的心情...',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedImage != null)
            Stack(
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedImage = null);
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

          const SizedBox(height: 20),

          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: Icon(Icons.image, color: theme.colorScheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : GradientButton(
                      text: '發布',
                      onPressed: (_textController.text.isNotEmpty || _selectedImage != null)
                          ? _submitMoment
                          : null,
                      height: 40,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
