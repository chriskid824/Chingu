import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.uid != null) {
        context.read<ChatProvider>().loadChatRooms(authProvider.uid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '聊天',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: chatProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : chatProvider.chatRooms.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '還沒有聊天室',
                  description: '開始配對以建立聊天！',
                  actionLabel: '開始配對',
                  onActionPressed: () => Navigator.of(context).pushNamed(AppRoutes.matching),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.uid != null) {
                      await chatProvider.loadChatRooms(authProvider.uid!);
                    }
                  },
                  child: ListView.builder(
                    itemCount: chatProvider.chatRooms.length,
                    itemBuilder: (context, index) {
                      final chatRoom = chatProvider.chatRooms[index];
                      return _buildChatRoomTile(context, chatRoom, theme, chinguTheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatRoomTile(
    BuildContext context,
    Map<String, dynamic> chatRoom,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    final otherUser = chatRoom['otherUser'];
    final lastMessage = chatRoom['lastMessage'] ?? '';
    final lastMessageAt = chatRoom['lastMessageAt'];
    final int unreadCount = chatRoom['unreadCount'] ?? 0;
    
    String timeText = '';
    if (lastMessageAt != null) {
      final timestamp = lastMessageAt.toDate();
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      if (difference.inDays == 0) {
        timeText = DateFormat('HH:mm').format(timestamp);
      } else if (difference.inDays < 7) {
        timeText = DateFormat('E HH:mm', 'zh_TW').format(timestamp);
      } else {
        timeText = DateFormat('MM/dd').format(timestamp);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.chatDetail,
          arguments: {
            'chatRoomId': chatRoom['chatRoomId'],
            'otherUser': otherUser,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: chinguTheme?.surfaceVariant ?? theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 頭像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: chinguTheme?.primaryGradient,
              ),
              child: Center(
                child: Text(
                  otherUser.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 訊息內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUser.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
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
