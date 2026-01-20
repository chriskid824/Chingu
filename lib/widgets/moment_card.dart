import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:intl/intl.dart';

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
      // If the parent updates the moment, we sync our local state
      // This might override optimistic updates if the API call hasn't finished yet
      // but it's necessary to keep data consistent.
      _isLiked = widget.moment.isLiked;
      _likeCount = widget.moment.likeCount;
      _commentCount = widget.moment.commentCount;
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
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    size: 20,
                    color: _isLiked ? (chinguTheme?.error ?? Colors.red) : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                label: '$_likeCount',
                textColor: _isLiked ? (chinguTheme?.error ?? Colors.red) : theme.colorScheme.onSurfaceVariant,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: '$_commentCount',
                textColor: theme.colorScheme.onSurfaceVariant,
                onTap: widget.onCommentTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.textColor,
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
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
