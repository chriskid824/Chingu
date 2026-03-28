import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
import 'package:chingu/utils/image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/providers/dinner_group_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentTab = 1; // 0: 群組聚餐, 1: 1對1 聊天 (預設 1對1)
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
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Very light gray-blue background
      appBar: _buildAppBar(theme, chinguTheme),
      body: SafeArea(
        child: chatProvider.isLoading
            ? const ChatListSkeleton()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _buildSegmentedControl(theme, chinguTheme),
                  const SizedBox(height: 16),
                  _buildSearchBar(theme, chinguTheme),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _currentTab == 0
                        ? _buildGroupChatTab(context, theme, chinguTheme)
                        : _buildOneOnOneTab(context, chatProvider, theme, chinguTheme),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ChinguTheme? chinguTheme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0, // Prevent color change on scroll
      leading: IconButton(
        icon: Icon(Icons.menu, color: theme.colorScheme.primary),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => (chinguTheme?.appBarTitleGradient ?? const LinearGradient(colors: [Color(0xFF6B93B8), Color(0xFF8DB6C9)])).createShader(bounds),
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
          icon: Icon(Icons.notifications, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
      ],
    );
  }


  Widget _buildSegmentedControl(ThemeData theme, ChinguTheme? chinguTheme) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSegmentTab(0, '群組聚餐', theme),
          _buildSegmentTab(1, '1對1 聊天', theme),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title, ThemeData theme) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ChinguTheme? chinguTheme) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: (chinguTheme?.surfaceVariant ?? theme.colorScheme.surfaceContainerHighest).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: TextStyle(fontSize: 15, color: theme.colorScheme.primary),
        decoration: InputDecoration(
          hintText: '搜尋聊天內容...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGroupChatTab(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    return Consumer<DinnerGroupProvider>(
      builder: (context, groupProvider, _) {
        if (groupProvider.isLoading) {
          return const ChatListSkeleton();
        }

        final groups = groupProvider.myGroups;
        
        // 過濾搜尋字串
        final filteredGroups = groups.where((group) {
          if (_searchQuery.isEmpty) return true;
          final title = '晚餐聚會 🥘';
          final restaurant = group.restaurantName ?? '';
          return title.toLowerCase().contains(_searchQuery) ||
                 restaurant.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredGroups.isEmpty) {
          return Center(
            child: Text(
              '沒有找到群組聚餐',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.uid != null) {
              await groupProvider.fetchMyGroups(authProvider.uid!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final group = filteredGroups[index];
              return _buildDinnerGroupBanner(context, theme, chinguTheme, group);
            },
          ),
        );
      },
    );
  }

  Widget _buildOneOnOneTab(
      BuildContext context, ChatProvider chatProvider, ThemeData theme, ChinguTheme? chinguTheme) {
    
    // 過濾搜尋字串
    final filteredRooms = chatProvider.chatRooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final otherUser = room['otherUser'];
      final lastMessage = room['lastMessage'] ?? '';
      final name = otherUser.name.toLowerCase();
      final msg = lastMessage.toLowerCase();
      return name.contains(_searchQuery) || msg.contains(_searchQuery);
    }).toList();

    if (filteredRooms.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.uid != null) {
          await chatProvider.loadChatRooms(authProvider.uid!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 80),
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = filteredRooms[index];
          // 加上一些變化的時間文字作為假資料展示 (如果沒有真實資料)
          return _buildChatCard(context, chatRoom, index, theme, chinguTheme);
        },
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, Map<String, dynamic> chatRoom, int index, ThemeData theme, ChinguTheme? chinguTheme) {
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
        // e.g. 週二
        final weekdays = ['週一','週二','週三','週四','週五','週六','週日'];
        timeText = weekdays[timestamp.weekday - 1];
      } else {
        timeText = DateFormat('MM/dd').format(timestamp);
      }
    }

    final isSystemMessage = lastMessage == '這則訊息已被收回';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar with online status badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E262C), // Dark circular background as fallback
                        image: otherUser.avatarUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  otherUser.avatarUrl!,
                                  cacheManager: ImageCacheManager().manager,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: otherUser.avatarUrl == null
                          ? Center(
                              child: Text(
                                otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    // Status dot (Green for online, or brown based on some logic)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: index % 3 == 0 ? (chinguTheme?.warning ?? Colors.orange) : (chinguTheme?.success ?? Colors.green), // Mock alternating status matching design
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
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
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage.isEmpty ? 'Say hi!' : lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSystemMessage ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontStyle: isSystemMessage ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Time & Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: (chinguTheme?.badgeColor ?? Colors.orange), // Characteristic reddish brown
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
                      const SizedBox(height: 20), // Placeholder to keep alignment
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '沒有找到對話',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 晚餐群組互動卡片結構
  Widget _buildDinnerGroupBanner(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme, DinnerGroupModel group) {
    final timeText = DateFormat('MM/dd').format(group.createdAt);
    final statusLabel = _groupStatusLabel(group.status);
    final title = group.restaurantName ?? '晚餐聚會 🥘';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.groupDetail,
              arguments: {'group': group},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 參與者大頭貼堆疊
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(left: 0, child: _buildMiniAvatar('👨')),
                      if (group.participantIds.length > 1)
                        Positioned(left: 15, child: _buildMiniAvatar('👧')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$statusLabel · ${group.participantIds.length} 人同桌',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
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

  String _groupStatusLabel(String status) {
    switch (status) {
      case 'pending': return '⏳ 等待揭曉';
      case 'info_revealed': return '👀 同伴已揭曉';
      case 'location_revealed': return '🎉 餐廳已揭曉';
      case 'completed': return '✅ 已結束';
      default: return status;
    }
  }

  Widget _buildMiniAvatar(String emoji) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF2F6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
