import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/notification_stats_provider.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '通知',
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
              if (provider.unreadCount == 0) return const SizedBox();
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
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Text(
                '目前沒有通知',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationItem(
                context,
                notification,
                provider,
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    NotificationStatsProvider provider,
  ) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    IconData icon;
    Color color;

    switch (notification.type) {
      case 'match':
        if (notification.title == '喜歡') {
          icon = Icons.favorite_rounded;
          color = theme.colorScheme.error;
        } else {
          icon = Icons.person_add_rounded;
          color = chinguTheme?.secondary ?? Colors.purple;
        }
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'event':
        if (notification.title == '提醒') {
           icon = Icons.restaurant_rounded;
           color = theme.colorScheme.primary;
        } else {
           icon = Icons.event_available_rounded;
           color = chinguTheme?.success ?? Colors.green;
        }
        break;
      case 'rating':
        icon = Icons.stars_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
    }

    // Since I don't have the exact strings for timeago messages like "2 小時前" in the mock data (I created DateTimes),
    // I will use a simple formatter or just hardcode if I want to match exactly, but dynamic is better.
    // However, I need to make sure I don't break existing behavior if possible.
    // The previous code had hardcoded strings. My mock data has relative times.
    // I'll use a simple helper for display since I didn't import timeago package in pubspec check.
    // Wait, the project might use timeago or intl. `intl` is there.
    // I'll implement a simple relative time helper.

    final timeString = _getRelativeTime(notification.createdAt);

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
      child: InkWell(
        onTap: () {
          provider.trackEngagement(notification.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
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
          title: Text(
            notification.message,
            style: TextStyle(
              fontWeight: !notification.isRead ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeString,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return '昨天';
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
}
