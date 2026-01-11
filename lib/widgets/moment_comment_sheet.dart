import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MomentCommentSheet extends StatefulWidget {
  final String momentId;

  const MomentCommentSheet({
    super.key,
    required this.momentId,
  });

  @override
  State<MomentCommentSheet> createState() => _MomentCommentSheetState();
}

class _MomentCommentSheetState extends State<MomentCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;

    if (userId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _firestoreService.addMomentComment(
        widget.momentId,
        userId,
        content,
      );
      _commentController.clear();
      // Keyboard might dismiss automatically or stay open, depending on UX preference.
      // Keeping it open for multiple comments is usually better.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate keyboard height to pad the bottom if needed,
    // but usually ModalBottomSheet handles this if isScrollControlled is true and padding is managed.
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Take up 75% of screen
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '評論',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(),

          // Comments List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMomentComments(widget.momentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('載入失敗: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      '還沒有評論，成為第一個評論的人吧！',
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
                    final createdAt = comment['createdAt'] as DateTime?;
                    final timeString = createdAt != null
                        ? DateFormat('MM/dd HH:mm').format(createdAt)
                        : '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: comment['userAvatar'] != null
                              ? CachedNetworkImageProvider(comment['userAvatar'])
                              : null,
                          child: comment['userAvatar'] == null
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '輸入評論...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : Icon(
                            Icons.send,
                            color: theme.colorScheme.primary,
                          ),
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
