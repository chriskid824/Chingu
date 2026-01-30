import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/models/comment_model.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:intl/intl.dart';

class MomentCard extends StatefulWidget {
  final MomentModel moment;

  const MomentCard({
    super.key,
    required this.moment,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard> {
  final MomentService _momentService = MomentService();
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
      _isLiked = widget.moment.isLiked;
      _likeCount = widget.moment.likeCount;
      _commentCount = widget.moment.commentCount;
    }
  }

  Future<void> _toggleLike() async {
    HapticUtils.light();
    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await _momentService.toggleLike(widget.moment.id, _isLiked);
    } catch (e) {
      // Revert
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentSheet(momentId: widget.moment.id),
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
                onTap: _showCommentSheet,
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

class _CommentSheet extends StatefulWidget {
  final String momentId;

  const _CommentSheet({required this.momentId});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  final MomentService _momentService = MomentService();
  bool _isSending = false;

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _momentService.addComment(widget.momentId, _controller.text.trim());
      _controller.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('發送失敗: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      margin: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
           // Handle
           Center(
             child: Container(
               margin: const EdgeInsets.symmetric(vertical: 10),
               width: 40,
               height: 4,
               decoration: BoxDecoration(
                 color: Colors.grey[300],
                 borderRadius: BorderRadius.circular(2),
               ),
             ),
           ),
           // Title
           Padding(
             padding: const EdgeInsets.only(bottom: 10),
             child: Text('留言', style: theme.textTheme.titleMedium),
           ),
           const Divider(height: 1),

           // List
           Expanded(
             child: StreamBuilder<List<CommentModel>>(
               stream: _momentService.getComments(widget.momentId),
               builder: (context, snapshot) {
                 if (snapshot.hasError) return Center(child: Text('錯誤: ${snapshot.error}'));
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                 final comments = snapshot.data!;
                 if (comments.isEmpty) return const Center(child: Text('還沒有留言，快來搶頭香！'));

                 return ListView.builder(
                   itemCount: comments.length,
                   padding: const EdgeInsets.all(16),
                   itemBuilder: (context, index) {
                     final comment = comments[index];
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           CircleAvatar(
                             radius: 18,
                             backgroundColor: theme.colorScheme.surfaceContainerHighest,
                             backgroundImage: comment.userAvatar != null
                               ? CachedNetworkImageProvider(comment.userAvatar!)
                               : null,
                             child: comment.userAvatar == null
                               ? Icon(Icons.person, size: 18, color: theme.colorScheme.onSurfaceVariant)
                               : null,
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   comment.userName,
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(comment.content, style: theme.textTheme.bodyMedium),
                                 const SizedBox(height: 4),
                                 Text(
                                   DateFormat('MM/dd HH:mm').format(comment.createdAt),
                                   style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                 ),
                               ],
                             ),
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
           Container(
             padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
             decoration: BoxDecoration(
               color: theme.cardColor,
               boxShadow: [
                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2)),
               ],
             ),
             child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _controller,
                     decoration: InputDecoration(
                       hintText: '輸入留言...',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                       filled: true,
                       fillColor: theme.scaffoldBackgroundColor,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     ),
                     minLines: 1,
                     maxLines: 4,
                   ),
                 ),
                 const SizedBox(width: 8),
                 IconButton(
                   icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                   color: theme.colorScheme.primary,
                   onPressed: _isSending ? null : _sendComment,
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}
