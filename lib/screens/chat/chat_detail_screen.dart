import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/typing_indicator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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
  Timer? _typingDebounce;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

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
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_chatRoomId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.uid;
    if (currentUserId == null) return;

    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();

    if (!_isTyping && _messageController.text.isNotEmpty) {
      _isTyping = true;
      context.read<ChatProvider>().setTypingStatus(
        chatRoomId: _chatRoomId!,
        userId: currentUserId,
        isTyping: true,
      );
    } else if (_isTyping && _messageController.text.isEmpty) {
      _isTyping = false;
      context.read<ChatProvider>().setTypingStatus(
        chatRoomId: _chatRoomId!,
        userId: currentUserId,
        isTyping: false,
      );
    }

    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatProvider>().setTypingStatus(
          chatRoomId: _chatRoomId!,
          userId: currentUserId,
          isTyping: false,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    _messageController.clear();

    try {
      await context.read<ChatProvider>().sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: currentUser.uid,
        text: text,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser!.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: context.read<ChatProvider>().getTypingStatusStream(
                          _chatRoomId!,
                          _otherUser!.uid,
                        ),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Text(
                          '正在輸入...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
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

                final messages = snapshot.data ?? [];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        // 如果沒有訊息，增加 1 個項目來顯示 Empty State (index=1)
                        // index=0 始終保留給 typing indicator
                        itemCount: messages.isEmpty ? 2 : messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                             // Typing indicator at the bottom (start of list because reversed)
                             return StreamBuilder<bool>(
                              stream: context.read<ChatProvider>().getTypingStatusStream(
                                    _chatRoomId!,
                                    _otherUser!.uid,
                                  ),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const TypingIndicator(),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          }

                          if (messages.isEmpty) {
                            if (index == 1) {
                               return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(
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
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          // Adjust index for messages
                          final messageIndex = index - 1;
                          if (messageIndex >= messages.length) return const SizedBox.shrink();

                          final message = messages[messageIndex];
                          final isMe = message['senderId'] == currentUserId;
                          return _buildMessageBubble(context, message, isMe);
                        },
                      ),
                    ),
                  ],
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

    return Align(
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
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(16),
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
    );
  }
}
