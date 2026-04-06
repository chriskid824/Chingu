import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/widgets/gif_picker.dart';
import 'package:chingu/widgets/geometric_avatar.dart';
import 'package:chingu/widgets/dialogs/report_dialog.dart';


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
  bool _isGroup = false;
  String _groupName = '';
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _chatRoomId = args['chatRoomId'];
        _otherUser = args['otherUser'];
        _isGroup = args['isGroup'] == true;
        _groupName = args['groupName'] as String? ?? '群組聊天';
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
      if (!mounted) return;
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
          SnackBar(content: Text('訊息發送失敗，請稍後再試')),
        );
      }
    }
  }

  void _sendGifMessage(String url) async {
    if (_chatRoomId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    try {
      await context.read<ChatProvider>().sendMessage(
        chatRoomId: _chatRoomId!,
        senderId: currentUser.uid,
        text: url,
        type: 'image',
      );
      if (!mounted) return;
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
          SnackBar(content: Text('訊息發送失敗，請稍後再試')),
        );
      }
    }
  }

  void _openGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GifPicker(
        onGifSelected: (url) {
          Navigator.pop(context);
          _sendGifMessage(url);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    if (_chatRoomId == null || (!_isGroup && _otherUser == null)) {
      return Scaffold(
        backgroundColor: AppColorsMinimal.background,
        body: const Center(child: CircularProgressIndicator(color: AppColorsMinimal.primary)),
      );
    }

    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.uid;

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isGroup
                    ? AppColorsMinimal.primary.withValues(alpha: 0.12)
                    : null,
                gradient: _isGroup ? null : AppColorsMinimal.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: _isGroup
                    ? Icon(Icons.groups_rounded, color: AppColorsMinimal.primary, size: 20)
                    : Text(
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
              _isGroup ? _groupName : _otherUser!.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColorsMinimal.background,
        elevation: 0,
        shadowColor: AppColorsMinimal.shadowLight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColorsMinimal.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColorsMinimal.textSecondary),
            onSelected: (value) async {
              final currentUserId = context.read<AuthProvider>().uid;
              if (currentUserId == null || _otherUser == null) return;

              if (value == 'report') {
                await ReportDialog.show(
                  context,
                  reporterId: currentUserId,
                  reportedUserId: _otherUser!.uid,
                  reportedUserName: _otherUser!.name,
                );
              } else if (value == 'block') {
                final result = await BlockConfirmDialog.show(
                  context,
                  userId: currentUserId,
                  blockedUserId: _otherUser!.uid,
                  blockedUserName: _otherUser!.name,
                );
                if (result == true && mounted) {
                  Navigator.of(context).pop(); // 封鎖後返回聊天列表
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppColorsMinimal.warning, size: 20),
                    SizedBox(width: 12),
                    Text('舉報用戶'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppColorsMinimal.error, size: 20),
                    SizedBox(width: 12),
                    Text('封鎖用戶'),
                  ],
                ),
              ),
            ],
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
                          color: AppColorsMinimal.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '開始聊天吧！',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColorsMinimal.textTertiary,
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
    final timestamp = message['timestamp'] as Timestamp?;
    final timeText = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '';

    final text = message['text'] ?? '';
    final type = message['type'] as String?;
    final isImage = (type == 'image' || type == 'gif') || (type == null && (text as String).endsWith('.gif'));
    final senderId = message['senderId'] as String? ?? '';

    // 訊息氣泡內容
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      padding: isImage
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: (isMe && !isImage) ? AppColorsMinimal.primaryGradient : null,
        color: (isMe && !isImage) ? null : AppColorsMinimal.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: text,
                placeholder: (context, url) => Container(
                  height: 150,
                  width: 150,
                  color: AppColorsMinimal.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  width: 150,
                  color: AppColorsMinimal.surfaceVariant,
                  child: const Icon(Icons.error),
                ),
              ),
            )
          else
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : AppColorsMinimal.textPrimary,
              ),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: isImage ? const EdgeInsets.only(left: 8, right: 8, bottom: 4) : EdgeInsets.zero,
            child: Text(
              timeText,
              style: TextStyle(
                color: (isMe && !isImage) ? Colors.white.withValues(alpha: 0.7) : AppColorsMinimal.textTertiary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    // 對方訊息：頭像 + 氣泡
    if (!isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GeometricAvatar(
              seed: senderId,
              photoUrl: _isGroup ? null : _otherUser?.avatarUrl,
              showPhoto: !_isGroup && PhotoVisibility.isDirectChatPhotoVisible(),
              size: 32,
            ),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
      );
    }

    // 自己的訊息：靠右
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: bubble,
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // GIF 按鈕（縮小）
            GestureDetector(
              onTap: _openGifPicker,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: AppColorsMinimal.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.gif_box_outlined, color: AppColorsMinimal.textTertiary, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // 輸入框
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColorsMinimal.surfaceVariant,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '輸入訊息...',
                    hintStyle: TextStyle(color: AppColorsMinimal.textTertiary, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 15, color: AppColorsMinimal.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 發送按鈕
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
