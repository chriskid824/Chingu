import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_group_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
import 'package:chingu/utils/image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      backgroundColor: AppColorsMinimal.background,
      body: SafeArea(
        child: chatProvider.isLoading
            ? const ChatListSkeleton()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      '聊天',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dinner group banner
                  _buildDinnerGroupBanner(context),

                  const SizedBox(height: 8),

                  // Chat list
                  Expanded(
                    child: chatProvider.chatRooms.isEmpty
                        ? _buildEmptyState(context, theme)
                        : RefreshIndicator(
                            onRefresh: () async {
                              final authProvider = context.read<AuthProvider>();
                              if (authProvider.uid != null) {
                                await chatProvider.loadChatRooms(authProvider.uid!);
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              itemCount: chatProvider.chatRooms.length,
                              itemBuilder: (context, index) {
                                final chatRoom = chatProvider.chatRooms[index];
                                return _buildChatRoomTile(context, chatRoom, theme, chinguTheme);
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Dinner group banner card
  Widget _buildDinnerGroupBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D6B5E),
              Color(0xFF3A8B7A),
              Color(0xFF4EADA0),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6B5E).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: countdown + avatars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Countdown badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '倒數 4 天',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Stacked avatars
                SizedBox(
                  width: 90,
                  height: 32,
                  child: Stack(
                    children: [
                      Positioned(left: 0, child: _buildMiniAvatar('🍕')),
                      Positioned(left: 20, child: _buildMiniAvatar('🌮')),
                      Positioned(left: 40, child: _buildMiniAvatar('🍜')),
                      Positioned(
                        left: 58,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '+3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            const Row(
              children: [
                Text('🍽', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  '本週晚餐 6 人群組',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '大家來打個招呼吧！',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(String emoji) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColorsMinimal.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍻', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '還沒有聊天室',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '參加晚餐活動並互相給予好評後\n即可在這裡解鎖專屬聊天室！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColorsMinimal.textTertiary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                final mainScreenState = context.findAncestorStateOfType<State>();
                if (mainScreenState != null && mainScreenState.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.mainNavigation,
                    arguments: {'initialIndex': 0},
                  );
                }
              },
              icon: const Icon(Icons.dinner_dining_rounded),
              label: const Text('去報名晚餐'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsMinimal.primary,
                side: BorderSide(color: AppColorsMinimal.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
                ),
              ),
            ),
          ],
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
        timeText = DateFormat('MM/dd').format(timestamp);
      } else {
        timeText = DateFormat('MM/dd').format(timestamp);
      }
    }

    // Get user age or rating for badge
    final int? age = otherUser.age;
    final double? rating = otherUser.averageRating;

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar - larger circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: otherUser.avatarUrl == null
                    ? AppColorsMinimal.primaryGradient
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: otherUser.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: otherUser.avatarUrl!,
                        cacheManager: ImageCacheManager().manager,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildAvatarFallback(otherUser.name),
                        errorWidget: (_, __, ___) => _buildAvatarFallback(otherUser.name),
                      ),
                    )
                  : _buildAvatarFallback(otherUser.name),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with badge and time
                  Row(
                    children: [
                      // Name
                      Flexible(
                        child: Text(
                          otherUser.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColorsMinimal.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Age or rating badge
                      if (rating != null && rating > 0)
                        _buildRatingBadge(rating)
                      else if (age != null && age > 0)
                        _buildAgeBadge(age),
                      const Spacer(),
                      // Time
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColorsMinimal.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Last message + unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? AppColorsMinimal.textPrimary
                                : AppColorsMinimal.textSecondary,
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
                        // Unread count badge (number, not dot)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColorsMinimal.primary,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAgeBadge(int age) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColorsMinimal.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${age}歲',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColorsMinimal.primary,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Color(0xFFFF9800)),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}
