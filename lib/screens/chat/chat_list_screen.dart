import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
import 'package:chingu/widgets/geometric_avatar.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentTab = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chinguTheme = Theme.of(context).extension<ChinguTheme>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: _buildAppBar(chinguTheme),
      body: SafeArea(
        child: chatProvider.isLoading
            ? const ChatListSkeleton()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppColorsMinimal.spaceSM),
                  _buildSegmentedControl(),
                  const SizedBox(height: AppColorsMinimal.spaceLG),
                  _buildSearchBar(),
                  const SizedBox(height: AppColorsMinimal.spaceLG),
                  Expanded(
                    child: _currentTab == 0
                        ? _buildGroupChatTab(context, chinguTheme)
                        : _buildOneOnOneTab(context, chatProvider, chinguTheme),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChinguTheme? chinguTheme) {
    return AppBar(
      backgroundColor: AppColorsMinimal.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppColorsMinimal.primary),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) =>
            (chinguTheme?.appBarTitleGradient ?? AppColorsMinimal.primaryGradient)
                .createShader(bounds),
        child: const Text(
          'Chingu',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: AppColorsMinimal.primary),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceXL),
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXS),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSegmentTab(0, '群組聚餐'),
          _buildSegmentTab(1, '1對1 聊天'),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColorsMinimal.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColorsMinimal.primary : AppColorsMinimal.textTertiary,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: TextStyle(fontSize: 15, color: AppColorsMinimal.primary),
        decoration: InputDecoration(
          hintText: '搜尋聊天內容...',
          hintStyle: TextStyle(color: AppColorsMinimal.textTertiary, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: AppColorsMinimal.textTertiary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGroupChatTab(BuildContext context, ChinguTheme? chinguTheme) {
    final chatProvider = context.watch<ChatProvider>();
    final groupRooms = chatProvider.groupChatRooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final name = (room['name'] as String).toLowerCase();
      final lastMsg = (room['lastMessage'] as String).toLowerCase();
      return name.contains(_searchQuery) || lastMsg.contains(_searchQuery);
    }).toList();

    if (groupRooms.isEmpty) {
      return _buildGroupEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.uid != null) {
          await chatProvider.loadChatRooms(authProvider.uid!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppColorsMinimal.spaceXL,
          vertical: AppColorsMinimal.spaceSM,
        ),
        itemCount: groupRooms.length,
        itemBuilder: (context, index) {
          return _buildGroupChatCard(context, groupRooms[index]);
        },
      ),
    );
  }

  Widget _buildOneOnOneTab(BuildContext context, ChatProvider chatProvider, ChinguTheme? chinguTheme) {
    final filteredRooms = chatProvider.chatRooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final otherUser = room['otherUser'];
      final lastMessage = room['lastMessage'] ?? '';
      return otherUser.name.toLowerCase().contains(_searchQuery) ||
          lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredRooms.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.uid != null) {
          await chatProvider.loadChatRooms(authProvider.uid!);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: AppColorsMinimal.spaceXL,
          right: AppColorsMinimal.spaceXL,
          top: AppColorsMinimal.spaceXS,
          bottom: 80,
        ),
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          return _buildChatCard(context, filteredRooms[index], index);
        },
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, Map<String, dynamic> chatRoom, int index) {
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
      } else if (difference.inDays == 1) {
        timeText = '昨天';
      } else if (difference.inDays < 7) {
        final weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
        timeText = weekdays[timestamp.weekday - 1];
      } else {
        timeText = DateFormat('MM/dd').format(timestamp);
      }
    }

    final isSystemMessage = lastMessage == '這則訊息已被收回';

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.spaceLG,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Avatar
                GeometricAvatar(
                  seed: otherUser.uid,
                  photoUrl: otherUser.avatarUrl,
                  showPhoto: PhotoVisibility.isDirectChatPhotoVisible(),
                  size: 52,
                  name: otherUser.name,
                ),
                const SizedBox(width: AppColorsMinimal.spaceLG),

                // Name & Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColorsMinimal.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppColorsMinimal.spaceXS),
                      Text(
                        lastMessage.isEmpty ? 'Say hi!' : lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSystemMessage
                              ? AppColorsMinimal.textTertiary
                              : AppColorsMinimal.textSecondary,
                          fontStyle: isSystemMessage ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppColorsMinimal.spaceMD),

                // Time & Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColorsMinimal.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: AppColorsMinimal.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColorsMinimal.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColorsMinimal.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColorsMinimal.shadowLight,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 40,
                  color: AppColorsMinimal.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceXL),
            Text(
              '還沒有對話',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceSM),
            Text(
              '參加晚餐互評後即可開始聊天',
              style: TextStyle(
                fontSize: 14,
                color: AppColorsMinimal.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChatCard(BuildContext context, Map<String, dynamic> room) {
    final name = room['name'] as String;
    final lastMessage = room['lastMessage'] as String;
    final lastMessageAt = room['lastMessageAt'];
    final int unreadCount = room['unreadCount'] ?? 0;
    final participantIds = room['participantIds'] as List;
    final chatRoomId = room['chatRoomId'] as String;

    String timeText = '';
    if (lastMessageAt != null) {
      final timestamp = lastMessageAt.toDate();
      final diff = DateTime.now().difference(timestamp);
      if (diff.inDays == 0) {
        timeText = DateFormat('HH:mm').format(timestamp);
      } else if (diff.inDays == 1) {
        timeText = '昨天';
      } else {
        timeText = DateFormat('MM/dd').format(timestamp);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chatDetail,
              arguments: {
                'chatRoomId': chatRoomId,
                'isGroup': true,
                'groupName': name,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.spaceLG,
              vertical: 14,
            ),
            child: Row(
              children: [
                // 群組圖標
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColorsMinimal.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: AppColorsMinimal.spaceLG),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColorsMinimal.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppColorsMinimal.spaceXS),
                      Text(
                        lastMessage.isEmpty
                            ? '${participantIds.length} 人群組'
                            : lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColorsMinimal.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppColorsMinimal.spaceMD),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColorsMinimal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: AppColorsMinimal.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColorsMinimal.space2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColorsMinimal.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColorsMinimal.shadowLight, blurRadius: 10),
                ],
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 40,
                color: AppColorsMinimal.textTertiary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceXL),
            Text(
              '還沒有群組聊天',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceSM),
            Text(
              '週三完全解鎖後會自動建立群組聊天室',
              style: TextStyle(
                fontSize: 14,
                color: AppColorsMinimal.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
