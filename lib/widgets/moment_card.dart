import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';

class MomentCard extends StatefulWidget {
  final MomentModel moment;
  final Function(bool isLiked)? onLikeChanged;
  final Function(bool isBookmarked)? onBookmarkChanged;
  final VoidCallback? onCommentTap;

  const MomentCard({
    super.key,
    required this.moment,
    this.onLikeChanged,
    this.onBookmarkChanged,
    this.onCommentTap,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.moment.isLiked;
    _likeCount = widget.moment.likeCount;
    _commentCount = widget.moment.commentCount;
    _isBookmarked = widget.moment.isBookmarked;
  }

  @override
  void didUpdateWidget(MomentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moment != oldWidget.moment) {
      _isLiked = widget.moment.isLiked;
      _likeCount = widget.moment.likeCount;
      _commentCount = widget.moment.commentCount;
      _isBookmarked = widget.moment.isBookmarked;
    }
  }

  void _toggleLike() {
    HapticUtils.light();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    widget.onLikeChanged?.call(_isLiked);
  }

  void _toggleBookmark() {
    HapticUtils.light();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    // 如果提供了回調，則調用；否則嘗試直接調用 FirestoreService
    if (widget.onBookmarkChanged != null) {
      widget.onBookmarkChanged!(_isBookmarked);
    } else {
      _handleBookmarkServiceCall();
    }
  }

  Future<void> _handleBookmarkServiceCall() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firestoreService = FirestoreService();
      if (authProvider.user != null) {
        if (_isBookmarked) {
          await firestoreService.bookmarkMoment(widget.moment.id, authProvider.user!.uid);
        } else {
          await firestoreService.unbookmarkMoment(widget.moment.id, authProvider.user!.uid);
        }
      }
    } catch (e) {
      // 錯誤處理：恢復狀態
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(
        moment: widget.moment,
        isBookmarked: _isBookmarked,
        onBookmarkToggle: () {
          Navigator.pop(context);
          _toggleBookmark();
        },
      ),
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
                onPressed: _showMoreOptions,
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
                onTap: widget.onCommentTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final MomentModel moment;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const _MoreOptionsSheet({
    required this.moment,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  void _handleShare(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '查看這個動態: ${moment.content}'));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製連結到剪貼簿')),
    );
  }

  void _handleReport(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舉報動態'),
        content: const Text('確定要舉報這則動態嗎？我們的團隊將會審核。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  await FirestoreService().submitMomentReport(
                    reporterId: authProvider.user!.uid,
                    reportedMomentId: moment.id,
                    reason: 'user_report',
                    description: 'User reported this moment',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('感謝您的舉報，我們將盡快處理')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('舉報失敗: $e')),
                  );
                }
              }
            },
            child: const Text('舉報', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
              title: Text('分享', style: theme.textTheme.bodyLarge),
              onTap: () => _handleShare(context),
            ),
            ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
              title: Text(
                isBookmarked ? '取消收藏' : '收藏',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: onBookmarkToggle,
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: theme.colorScheme.error),
              title: Text(
                '舉報',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
              ),
              onTap: () => _handleReport(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
