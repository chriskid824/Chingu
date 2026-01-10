import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/providers/notification_stats_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 進入頁面時刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationStatsProvider>().loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationStatsProvider>().loadNotifications();
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // 標記為已讀
    if (!notification.isRead) {
      context.read<NotificationStatsProvider>().markAsRead(notification.id);
    }

    // 處理導航
    if (notification.actionType != null) {
      // 根據 actionType 導航
      switch (notification.actionType) {
        case 'open_chat':
           if (notification.actionData != null) {
             // 這裡假設 actionData 可能是 JSON 或直接 ID
             // 為了簡單，如果 actionData 是 string 且看起來像 ID
             // 實際應用中需要根據數據結構解析
             // 這裡先只處理簡單的聊天導航，需要 ChatDetailScreen 參數
             // 由於需要 UserModel，這裡可能比較複雜，通常需要先 fetch chat room or user
             // 這裡暫時只導航到 ChatListScreen 如果沒有完整數據
             Navigator.pushNamed(context, AppRoutes.chatList);
           }
           break;
        case 'open_event':
           // 類似，導航到活動詳情
           if (notification.actionData != null) {
              // Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: ...);
              // 因為沒有足夠數據，暫時導航到列表
              Navigator.pushNamed(context, AppRoutes.eventsList);
           }
           break;
        case 'navigate':
           if (notification.actionData != null) {
             Navigator.pushNamed(context, notification.actionData!);
           }
           break;
        default:
          // 默認行為
          break;
      }
    } else {
      // 根據 type 做默認導航
      switch (notification.type) {
        case 'message':
          Navigator.pushNamed(context, AppRoutes.chatList);
          break;
        case 'match':
          Navigator.pushNamed(context, AppRoutes.matching); // 或新的配對列表
          break;
        case 'event':
          Navigator.pushNamed(context, AppRoutes.eventsList);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '通知中心',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          Consumer<NotificationStatsProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  provider.markAllAsRead();
                },
                child: Text(
                  '全部已讀',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationStatsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadNotifications(refresh: true);
            },
            color: theme.colorScheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                return _buildNotificationItem(context, notification, theme, chinguTheme);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '沒有新通知',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '您目前沒有任何通知消息',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    // 根據類型決定圖標和顏色
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'match':
        icon = Icons.favorite_rounded;
        color = theme.colorScheme.error;
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'event':
        icon = Icons.event_available_rounded;
        color = chinguTheme?.success ?? Colors.green;
        break;
      case 'rating':
        icon = Icons.stars_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
    }

    // 格式化時間
    final diff = DateTime.now().difference(notification.createdAt);
    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = '剛剛';
    } else if (diff.inHours < 1) {
      timeStr = '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      timeStr = '${diff.inHours} 小時前';
    } else {
      timeStr = '${diff.inDays} 天前';
      if (diff.inDays == 1) timeStr = '昨天';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: !notification.isRead ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !notification.isRead
              ? theme.colorScheme.primary.withOpacity(0.2)
              : chinguTheme?.surfaceVariant ?? theme.dividerColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: !notification.isRead ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: chinguTheme?.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
