import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock data for notifications
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _loadMockNotifications();
  }

  void _loadMockNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        userId: 'current_user',
        type: 'match',
        title: '新的配對',
        message: '王小華 喜歡了您的個人資料',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        userId: 'current_user',
        type: 'message',
        title: '新訊息',
        message: '李小美 傳送了一則訊息給您',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        userId: 'current_user',
        type: 'event',
        title: '活動提醒',
        message: '您與 陳大明 的晚餐預約已確認',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        userId: 'current_user',
        type: 'rating',
        title: '成就解鎖',
        message: '恭喜！您獲得了新的成就徽章',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        userId: 'current_user',
        type: 'system',
        title: '配對建議',
        message: '林小芳 想要與您配對',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        userId: 'current_user',
        type: 'event',
        title: '活動通知',
        message: '本週三晚餐報名即將截止',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.markAsRead()).toList();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite_rounded;
      case 'event':
        return Icons.event_available_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'rating':
        return Icons.stars_rounded;
      case 'system':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type, ChinguTheme? chinguTheme, ColorScheme colorScheme) {
    switch (type) {
      case 'match':
        return colorScheme.error;
      case 'event':
        return chinguTheme?.warning ?? Colors.orange;
      case 'message':
        return colorScheme.primary;
      case 'rating':
        return chinguTheme?.success ?? Colors.amber;
      case 'system':
      default:
        return chinguTheme?.secondary ?? colorScheme.secondary;
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
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                '全部已讀',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(theme, chinguTheme)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(
                  context,
                  _notifications[index],
                  theme,
                  chinguTheme,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ChinguTheme? chinguTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '目前沒有新通知',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '所有的通知都會顯示在這裡',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type, chinguTheme, theme.colorScheme);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? theme.colorScheme.primary.withOpacity(0.2)
                : chinguTheme?.surfaceVariant ?? theme.dividerColor,
            width: 1,
          ),
        ),
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
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          trailing: isUnread
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            // Mark as read when tapped
            if (isUnread) {
              setState(() {
                final index = _notifications.indexWhere((n) => n.id == notification.id);
                if (index != -1) {
                  _notifications[index] = _notifications[index].markAsRead();
                }
              });
            }
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
