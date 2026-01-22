import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_storage_service.dart';
import '../../services/rich_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          StreamBuilder<int>(
            stream: _storageService.watchUnreadCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data! > 0) {
                return TextButton(
                  onPressed: () {
                    _storageService.markAllAsRead();
                  },
                  child: Text(
                    '全部已讀',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _storageService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(context, notifications[index]);
            },
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

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // 根據類型決定圖標和顏色
    final iconData = _getIconData(notification.iconName);
    final iconColor = _getIconColor(notification.type, chinguTheme, theme);

    // 格式化時間
    final timeStr = _formatTime(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _storageService.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          // 標記為已讀
          if (!notification.isRead) {
            _storageService.markAsRead(notification.id);
          }
          // 執行導航
          _richNotificationService.handleNotificationAction(
            notification.actionType,
            notification.actionData,
            null, // actionId is usually for buttons, here we just tap the body
          );
        },
        child: Container(
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildLeading(notification, iconData, iconColor, chinguTheme),
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
                if (notification.message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _buildLeading(
    NotificationModel notification,
    IconData iconData,
    Color iconColor,
    ChinguTheme? chinguTheme
  ) {
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: chinguTheme?.surfaceVariant ?? Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: notification.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200],
              child: Icon(iconData, color: iconColor, size: 24),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'favorite': return Icons.favorite_rounded;
      case 'event': return Icons.calendar_today_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'star': return Icons.star_rounded;
      case 'notifications':
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type, ChinguTheme? chinguTheme, ThemeData theme) {
    if (chinguTheme == null) return theme.colorScheme.primary;

    switch (type) {
      case 'match':
        return chinguTheme.error;
      case 'event':
        return theme.colorScheme.primary;
      case 'message':
        return chinguTheme.info;
      case 'rating':
        return chinguTheme.warning;
      case 'system':
      default:
        return chinguTheme.success;
    }
  }

  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
    }
  }
}
