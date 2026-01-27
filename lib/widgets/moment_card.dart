import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  void _toggleLike() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;
    if (userId == null) return;

    HapticUtils.light();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      _momentService.likeMoment(widget.moment.id, userId);
    } else {
      _momentService.unlikeMoment(widget.moment.id, userId);
    }
    widget.onLikeChanged?.call(_isLiked);
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(momentId: widget.moment.id),
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
                onTap: widget.onCommentTap ?? _showComments,
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

class _CommentsSheet extends StatefulWidget {
  final String momentId;

  const _CommentsSheet({required this.momentId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final MomentService _momentService = MomentService();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    final content = text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user != null) {
      // Optimistically we could add it to local list, but streaming handles it.
      await _momentService.addComment(
        widget.momentId,
        user.uid,
        user.name,
        user.avatarUrl,
        content
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Text(
                '評論',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // List
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: _momentService.getCommentsStream(widget.momentId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          '尚無評論，來搶頭香吧！',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                          ),
                        )
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: comment.userAvatar != null ? CachedNetworkImageProvider(comment.userAvatar!) : null,
                            child: comment.userAvatar == null ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant) : null,
                          ),
                          title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.content),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MM/dd HH:mm').format(comment.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: '新增評論...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _isComposing = text.trim().isNotEmpty;
                            });
                          },
                          onSubmitted: _isComposing ? _handleSubmitted : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: _isComposing ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        onPressed: _isComposing ? () => _handleSubmitted(_controller.text) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
