import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/models/models.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MomentCommentsSheet extends StatefulWidget {
  final String momentId;

  const MomentCommentsSheet({super.key, required this.momentId});

  @override
  State<MomentCommentsSheet> createState() => _MomentCommentsSheetState();
}

class _MomentCommentsSheetState extends State<MomentCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final MomentService _momentService = MomentService();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment(AuthProvider authProvider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = authProvider.userModel;
    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final comment = CommentModel(
        id: '', // Will be set by service
        momentId: widget.momentId,
        userId: user.uid,
        userName: user.name,
        userAvatar: user.avatarUrl,
        content: text,
        createdAt: DateTime.now(),
      );

      await _momentService.addComment(widget.momentId, comment);
      _controller.clear();
      // Unfocus keyboard if needed, or keep it open for multiple comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Comments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(height: 1),

          // Comments List
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _momentService.getComments(widget.momentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(comment: comment);
                  },
                );
              },
            ),
          ),

          // Input Area
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 16,
                     backgroundImage: authProvider.userModel?.avatarUrl != null
                         ? CachedNetworkImageProvider(authProvider.userModel!.avatarUrl!)
                         : null,
                     child: authProvider.userModel?.avatarUrl == null
                         ? const Icon(Icons.person, size: 20)
                         : null,
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: TextField(
                       controller: _controller,
                       decoration: const InputDecoration(
                         hintText: 'Add a comment...',
                         border: InputBorder.none,
                         isDense: true,
                       ),
                       maxLines: null,
                       textInputAction: TextInputAction.send,
                       onSubmitted: (_) => _sendComment(authProvider),
                     ),
                   ),
                   IconButton(
                     icon: _isSending
                         ? const SizedBox(
                             width: 24,
                             height: 24,
                             child: CircularProgressIndicator(strokeWidth: 2)
                           )
                         : Icon(Icons.send, color: theme.colorScheme.primary),
                     onPressed: _isSending ? null : () => _sendComment(authProvider),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentModel comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = DateFormat('MM/dd HH:mm').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.userAvatar != null
                ? CachedNetworkImageProvider(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
