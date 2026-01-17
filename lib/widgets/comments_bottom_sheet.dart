import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/models.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String momentId;

  const CommentsBottomSheet({super.key, required this.momentId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final MomentService _momentService = MomentService();
  bool _isComposing = false;

  void _handleSubmitted(String text, UserModel user) {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() {
      _isComposing = false;
    });

    final comment = CommentModel(
      id: '', // Set by service or ignored
      userId: user.uid,
      userName: user.name,
      userAvatar: user.avatarUrl,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    _momentService.addComment(widget.momentId, comment);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _momentService.getCommentsStream(widget.momentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No comments yet'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                         backgroundImage: comment.userAvatar != null ? CachedNetworkImageProvider(comment.userAvatar!) : null,
                         child: comment.userAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const SizedBox(height: 4),
                            Text(comment.content, style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MM/dd HH:mm').format(comment.createdAt), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Extra bottom padding for safe area
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _isComposing ? () => _handleSubmitted(_controller.text, user) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
