import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notifications = await _notificationService.fetchNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback to empty state on error for now
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法載入通知: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    try {
      await _notificationService.markAllAsRead(userId);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全部通知已標記為已讀')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失敗: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);
        setState(() {
           // Optimistic update
           final index = _notifications.indexWhere((n) => n.id == notification.id);
           if (index != -1) {
             _notifications[index] = notification.markAsRead();
           }
        });
      } catch (_) {
        // Ignore error for read marking
      }
    }

    if (!mounted) return;

    // Handle navigation
    if (notification.actionType != null) {
        switch (notification.actionType) {
            case 'match':
            case 'open_chat':
                 if (notification.actionData != null) {
                     Navigator.of(context).pushNamed(
                         AppRoutes.chatDetail,
                         arguments: {'chatRoomId': notification.actionData}, // Assuming actionData is chatRoomId or similar
                     );
                 } else {
                     Navigator.of(context).pushNamed(AppRoutes.chatList);
                 }
                 break;
            case 'event':
                 if (notification.actionData != null) {
                     // Assuming we can pass ID, but EventDetailScreen might need object?
                     // Based on memory: "UserDetailScreen and EventDetailScreen do not currently consume route arguments... they display hardcoded or internally managed data."
                     // So we might just navigate there for now.
                     Navigator.of(context).pushNamed(AppRoutes.eventDetail);
                 } else {
                     Navigator.of(context).pushNamed(AppRoutes.eventsList);
                 }
                 break;
            case 'navigate':
                 if (notification.actionData != null) {
                     Navigator.of(context).pushNamed(notification.actionData!);
                 }
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        theme,
                        chinguTheme,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
    // Determine icon and color based on type
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'match':
        iconData = Icons.favorite_rounded;
        iconColor = theme.colorScheme.error;
        break;
      case 'message':
        iconData = Icons.chat_bubble_rounded;
        iconColor = theme.colorScheme.primary;
        break;
      case 'event':
        iconData = Icons.event_available_rounded;
        iconColor = chinguTheme?.success ?? Colors.green;
        break;
      case 'rating':
        iconData = Icons.stars_rounded;
        iconColor = chinguTheme?.warning ?? Colors.amber;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        iconColor = theme.colorScheme.secondary;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead ? theme.cardColor : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? chinguTheme?.surfaceVariant ?? theme.dividerColor
              : theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
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
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title, // Or message depending on design. Using title as main text here if available?
                        // The model has both title and message. Let's show Title bold, message normal.
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (notification.message.isNotEmpty && notification.message != notification.title)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8, top: 8),
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
      return '${time.year}/${time.month}/${time.day}';
    }
  }
}
