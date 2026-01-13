import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CommentBottomSheet extends StatefulWidget {
  final String momentId;
  final Stream<List<Map<String, dynamic>>> commentsStream;
  final Function(String content) onAddComment;

  const CommentBottomSheet({
    super.key,
    required this.momentId,
    required this.commentsStream,
    required this.onAddComment,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isComposing = _controller.text.trim().isNotEmpty;
      if (_isComposing != isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    try {
      await widget.onAddComment(content);
    } catch (e) {
      // In case of error, restore text (simple approach) or show toast
      // For now we just print/ignore, but at least we don't block
      // Ideally we would restore _controller.text = content;
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
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '留言',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('無法載入留言'));
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      '還沒有人留言，來搶頭香吧！',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final timestamp = comment['createdAt'] != null
                        ? (comment['createdAt'] as Timestamp).toDate()
                        : DateTime.now();
                    final timeString = DateFormat('MM/dd HH:mm').format(timestamp);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: comment['userAvatar'] != null
                              ? CachedNetworkImageProvider(comment['userAvatar'])
                              : null,
                          child: comment['userAvatar'] == null
                              ? Icon(Icons.person, size: 20, color: theme.colorScheme.onSurfaceVariant)
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
                                    comment['userName'] ?? 'Unknown',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeString,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['content'] ?? '',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: '新增留言...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: chinguTheme?.surfaceVariant ?? Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isComposing ? _handleSubmit : null,
                  icon: Icon(
                    Icons.send,
                    color: _isComposing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
