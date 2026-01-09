import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/reply_message_widget.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatRoomId;
  UserModel? _otherUser;
  bool _isInit = false;

  // State for replying
  Map<String, dynamic>? _replyMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _chatRoomId = args['chatRoomId'];
        _otherUser = args['otherUser'];
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    // Capture reply info before clearing
    final replyToMessageId = _replyMessage?['id'];
    final replyToMessageText = _replyMessage?['text'];
    // Determine the sender name for the reply
    String? replyToSenderName;
    if (_replyMessage != null) {
       final isReplyToMe = _replyMessage!['senderId'] == currentUser.uid;
       replyToSenderName = isReplyToMe ? '你' : (_otherUser?.name ?? '未知');
    }

    _messageController.clear();
    _cancelReply();

    try {
      await context.read<ChatProvider>().sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: currentUser.uid,
        text: text,
        replyToMessageId: replyToMessageId,
        replyToMessageText: replyToMessageText,
        replyToSenderName: replyToSenderName,
      );
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_chatRoomId == null || _otherUser == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  _otherUser!.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _otherUser!.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        shadowColor: theme.shadowColor.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<ChatProvider>().getMessages(_chatRoomId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '開始聊天吧！',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;
                    return _buildMessageBubble(context, message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message, bool isMe) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final timestamp = message['timestamp'] as Timestamp?;
    final timeText = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '';

    // Reply info in message
    final replyToSenderName = message['replyToSenderName'];
    final replyToMessageText = message['replyToMessageText'];
    final hasReply = replyToSenderName != null && replyToMessageText != null;

    final bubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? chinguTheme?.primaryGradient : null,
          color: isMe ? null : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasReply)
               Container(
                 margin: const EdgeInsets.only(bottom: 8),
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                   border: Border(
                     left: BorderSide(
                       color: isMe ? Colors.white.withOpacity(0.5) : theme.colorScheme.primary,
                       width: 3,
                     ),
                   ),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       replyToSenderName ?? '',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: isMe ? Colors.white.withOpacity(0.9) : theme.colorScheme.primary,
                       ),
                     ),
                     const SizedBox(height: 2),
                     Text(
                       replyToMessageText ?? '',
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         fontSize: 12,
                         color: isMe ? Colors.white.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.6),
                       ),
                     ),
                   ],
                 ),
               ),
            Text(
              message['text'] ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMe ? Colors.white.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with Dismissible for Swipe to Reply
    return Dismissible(
      key: Key(message['id'] ?? UniqueKey().toString()),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.userModel;

        // Determine name for the preview when swiping
        String displayName = '未知';
        if (message['senderId'] == currentUser?.uid) {
          displayName = '你';
        } else {
          displayName = _otherUser?.name ?? '對方';
        }

        // Inject a temporary sender name into the message map for the ReplyMessageWidget to use
        // Note: we don't modify the original message map permanently in firestore here, just local state
        final replyMsg = Map<String, dynamic>.from(message);
        replyMsg['senderName'] = displayName; // Use senderName key to match expectation if any, or just used in logic

        setState(() {
          _replyMessage = replyMsg;
        });

        // Focus the text field
        // We need a small delay because the keyboard might be animating
        Future.delayed(const Duration(milliseconds: 100), () {
           // This focuses the keyboard
           // We might need a FocusNode if _messageController doesn't automatically trigger it
           // But usually just setting state is enough if the TextField is built.
           // However, to pop keyboard we might need:
           // FocusScope.of(context).requestFocus(_focusNode);
        });

        return false; // Do not dismiss
      },
      child: bubble,
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.userModel;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyMessage != null)
              ReplyMessageWidget(
                senderName: _replyMessage!['senderName'] ?? (_replyMessage!['senderId'] == currentUser?.uid ? '你' : (_otherUser?.name ?? '')),
                messageText: _replyMessage!['text'] ?? '',
                onCancel: _cancelReply,
              ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '輸入訊息...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: chinguTheme?.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
