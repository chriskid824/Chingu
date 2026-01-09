import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Mock data based on previous implementation
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
        title: '預約確認',
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
        type: 'match',
        title: '配對請求',
        message: '林小芳 想要與您配對',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        userId: 'current_user',
        type: 'system',
        title: '系統提醒',
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '目前沒有通知',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: theme.colorScheme.error,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(notification.id);
                  },
                  child: _buildNotificationItem(context, notification, theme, chinguTheme),
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
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case 'match':
        iconColor = theme.colorScheme.error;
        iconData = Icons.favorite_rounded;
        break;
      case 'message':
        iconColor = theme.colorScheme.primary;
        iconData = Icons.chat_bubble_rounded;
        break;
      case 'event':
        iconColor = chinguTheme?.success ?? Colors.green;
        iconData = Icons.event_available_rounded;
        break;
      case 'rating':
        iconColor = chinguTheme?.warning ?? Colors.amber;
        iconData = Icons.stars_rounded;
        break;
      case 'system':
      default:
        iconColor = chinguTheme?.secondary ?? Colors.purple;
        iconData = Icons.notifications_rounded;
        break;
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(0.2),
                iconColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          notification.message, // Using message as the main text as per design
          style: TextStyle(
            fontWeight: !notification.isRead ? FontWeight.w600 : FontWeight.normal,
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
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            setState(() {
              final index = _notifications.indexWhere((n) => n.id == notification.id);
              if (index != -1) {
                _notifications[index] = _notifications[index].markAsRead();
              }
            });
          }
          // TODO: Handle navigation based on notification.actionType
        },
      ),
    );
  }
}
