import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/widgets/custom_bottom_sheet.dart';

class MomentCard extends StatefulWidget {
  final MomentModel moment;
  final Function(bool isLiked)? onLikeChanged;
  final VoidCallback? onCommentTap;

  const MomentCard({
    super.key,
    required this.moment,
    this.onLikeChanged,
    this.onCommentTap,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  final MomentService _momentService = MomentService();
  bool _isProcessingLike = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.moment.isLiked;
    _likeCount = widget.moment.likeCount;
    _commentCount = widget.moment.commentCount;
  }

  @override
  void didUpdateWidget(MomentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moment != oldWidget.moment) {
      _isLiked = widget.moment.isLiked;
      _likeCount = widget.moment.likeCount;
      _commentCount = widget.moment.commentCount;
    }
  }

  Future<void> _toggleLike() async {
    if (_isProcessingLike) return;
    _isProcessingLike = true;

    HapticUtils.light();

    final authProvider = context.read<AuthProvider>();
    if (authProvider.uid == null) {
      _isProcessingLike = false;
      return;
    }

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await _momentService.toggleLike(widget.moment.id, authProvider.uid!);
      widget.onLikeChanged?.call(_isLiked);
    } catch (e) {
      // Revert on error
      setState(() {
         _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失敗: $e')),
      );
    } finally {
      _isProcessingLike = false;
    }
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsBottomSheet(momentId: widget.moment.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final timeString = DateFormat('MM/dd HH:mm').format(widget.moment.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: widget.moment.userAvatar != null
                    ? CachedNetworkImageProvider(widget.moment.userAvatar!)
                    : null,
                child: widget.moment.userAvatar == null
                    ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.moment.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            widget.moment.content,
            style: theme.textTheme.bodyLarge,
          ),

          if (widget.moment.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.moment.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: '$_likeCount',
                color: _isLiked ? (chinguTheme?.error ?? Colors.red) : theme.colorScheme.onSurfaceVariant,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: '$_commentCount',
                color: theme.colorScheme.onSurfaceVariant,
                onTap: () {
                  widget.onCommentTap?.call();
                  _showCommentsBottomSheet();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String momentId;

  const _CommentsBottomSheet({required this.momentId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final MomentService _momentService = MomentService();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _momentService.addComment(
        widget.momentId,
        user.uid,
        content,
        user.name,
        user.avatarUrl,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送評論失敗: $e')),
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

  Future<void> _deleteComment(String commentId) async {
    try {
      await _momentService.deleteComment(widget.momentId, commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('評論已刪除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除評論'),
        content: const Text('確定要刪除這則評論嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return CustomBottomSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '評論',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _momentService.getCommentsStream(widget.momentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('加載評論失敗: ${snapshot.error}'));
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        '還沒有評論，來搶頭香吧！',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isMyComment = comment.userId == authProvider.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.userAvatar != null
                              ? CachedNetworkImageProvider(comment.userAvatar!)
                              : null,
                          child: comment.userAvatar == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.content),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MM/dd HH:mm').format(comment.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        onLongPress: isMyComment ? () => _confirmDeleteComment(comment.id) : null,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '輸入評論...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
