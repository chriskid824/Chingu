import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_router.dart';
import '../../models/notification_model.dart';
import '../../services/notification_storage_service.dart';
import '../../widgets/empty_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();

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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          StreamBuilder<int>(
            stream: _storageService.watchUnreadCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _storageService.markAllAsRead();
                  if (!mounted) return;

                  messenger.showSnackBar(
                    const SnackBar(content: Text('已全部標記為已讀')),
                  );
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
      body: StreamBuilder<List<NotificationModel>>(
        stream: _storageService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('加載失敗: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: '沒有新通知',
              description: '您目前沒有任何通知消息',
              iconColor: theme.colorScheme.primary.withOpacity(0.5),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification, theme, chinguTheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        _storageService.deleteNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !notification.isRead
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildNotificationIcon(notification, theme, chinguTheme),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: !notification.isRead ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
    NotificationModel notification,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'match':
        icon = Icons.favorite_rounded;
        color = theme.colorScheme.error; // Pink/Red
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = theme.colorScheme.primary; // Blue
        break;
      case 'event':
        icon = Icons.event_available_rounded;
        color = chinguTheme?.success ?? Colors.green;
        break;
      case 'rating':
        icon = Icons.star_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // 標記為已讀
    if (!notification.isRead) {
      _storageService.markAsRead(notification.id);
    }

    final navigator = Navigator.of(context);
    final actionType = notification.actionType;
    final actionData = notification.actionData;

    if (actionType == null) return;

    switch (actionType) {
      case 'open_chat':
        // 導航到聊天列表
        // 理想情況下如果 actionData 是 chatRoomId 且我們能獲取 userModel，可以導航到 chatDetail
        // 但目前簡單起見，導航到列表
        navigator.pushNamed(AppRoutes.chatList);
        break;

      case 'view_event':
        // 導航到活動詳情
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.eventDetail, arguments: actionData);
        } else {
          navigator.pushNamed(AppRoutes.eventsList);
        }
        break;

      case 'match_history':
      case 'match':
        // 導航到配對列表
        navigator.pushNamed(AppRoutes.matchesList);
        break;

      case 'navigate':
        // 通用導航
        if (actionData != null) {
          try {
            navigator.pushNamed(actionData);
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        }
        break;

      default:
        // 不做任何操作或顯示詳情
        break;
    }
  }
}
