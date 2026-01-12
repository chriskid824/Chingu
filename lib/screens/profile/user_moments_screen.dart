import 'dart:io';

import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/widgets/moment_comment_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UserMomentsScreen extends StatefulWidget {
  final String? userId; // If null, show all moments (feed)

  const UserMomentsScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  List<MomentModel> _moments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoments();
    }
  }

  Future<void> _loadMoments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.uid;

      Map<String, dynamic> result;

      if (widget.userId != null) {
        result = await _firestoreService.getMomentsByUserId(
          widget.userId!,
          lastDocument: _lastDocument,
          currentUserId: currentUserId,
        );
      } else {
        result = await _firestoreService.getMoments(
          lastDocument: _lastDocument,
          currentUserId: currentUserId,
        );
      }

      final newMoments = result['moments'] as List<MomentModel>;
      final lastDoc = result['lastDocument'] as DocumentSnapshot?;
      final hasMore = result['hasMore'] as bool;

      setState(() {
        if (_lastDocument == null) {
          _moments = newMoments;
        } else {
          _moments.addAll(newMoments);
        }
        _lastDocument = lastDoc;
        _hasMore = hasMore;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加載動態失敗: $e')),
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

  Future<void> _refresh() async {
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadMoments();
  }

  void _openCreateMoment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateMomentSheet(),
    ).then((_) {
      // Refresh after creation if user actually created something
      // For simplicity, just refresh always for now
      _refresh();
    });
  }

  void _showComments(String momentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return MomentCommentSheet(
            momentId: momentId,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isCurrentUser = widget.userId == null || widget.userId == authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? '動態牆' : '個人動態'),
        actions: [
          if (isCurrentUser)
            AppIconButton(
              icon: Icons.add,
              onTap: _openCreateMoment,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _moments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暫無動態',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(height: 24),
                            GradientButton(
                              text: '發布第一則動態',
                              onPressed: _openCreateMoment,
                              width: 200,
                            ),
                          ]
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _moments.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _moments.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final moment = _moments[index];
                        return MomentCard(
                          moment: moment,
                          onLikeChanged: (isLiked) {
                            _firestoreService.toggleMomentLike(
                              moment.id,
                              authProvider.currentUser!.uid,
                              isLiked,
                            );
                          },
                          onCommentTap: () => _showComments(moment.id),
                        );
                      },
                    ),
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
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _publish() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'moments/${currentUser.uid}/$timestamp.jpg';
        final task = _storageService.uploadFile(_selectedImage!, path);

        await task;
        imageUrl = await _storageService.getDownloadUrl(path);
      }

      final moment = MomentModel(
        id: '', // Generated by Firestore
        userId: currentUser.uid,
        userName: currentUser.name,
        userAvatar: currentUser.avatarUrl,
        content: text,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createMoment(moment);

      if (mounted) {
        Navigator.pop(context);
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
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Text(
                  '建立動態',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : GradientButton(
                        text: '發布',
                        onPressed: (_textController.text.isNotEmpty || _selectedImage != null)
                            ? _publish
                            : null,
                        width: 80,
                        height: 36,
                      ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '分享你的想法...',
                border: InputBorder.none,
              ),
              maxLines: 5,
              onChanged: (_) => setState(() {}),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
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
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image,
                    color: chinguTheme?.primary ?? theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '添加照片',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
