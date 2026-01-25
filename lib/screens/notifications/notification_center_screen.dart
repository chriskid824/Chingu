import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _notificationService =
      NotificationStorageService();
  bool _isLoading = false;

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read immediately
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    if (!mounted) return;

    // 2. Handle Action
    if (notification.actionType == null) return;

    final actionType = notification.actionType;
    final actionData = notification.actionData;

    if (actionData == null) return;

    try {
      if (actionType == 'navigate') {
        if (mounted) Navigator.pushNamed(context, actionData);
      } else if (actionType == 'open_event' || actionType == 'view_event') {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {'eventId': actionData},
          );
        }
      } else if (actionType == 'open_chat') {
        setState(() => _isLoading = true);

        final currentUser = context.read<AuthProvider>().userModel;
        if (currentUser == null) {
          setState(() => _isLoading = false);
          return;
        }

        final chatService = ChatService();
        final firestoreService = FirestoreService();

        // Get or create chat room
        final chatRoomId = await chatService.createChatRoom(
          currentUser.uid,
          actionData, // Target user ID
        );

        // Get target user data
        final otherUser = await firestoreService.getUser(actionData);

        if (mounted) {
          setState(() => _isLoading = false);
          if (otherUser != null) {
            Navigator.pushNamed(
              context,
              AppRoutes.chatDetail,
              arguments: {
                'chatRoomId': chatRoomId,
                'otherUser': otherUser,
              },
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('無法找到該用戶')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
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
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notificationService.markAllAsRead();
            },
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
      body: Stack(
        children: [
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.watchNotifications(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('載入失敗: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '目前沒有新通知',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(
                      context, notification, theme, chinguTheme);
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
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
      case 'event':
        iconData = Icons.event_rounded;
        iconColor = chinguTheme?.success ?? Colors.green;
        break;
      case 'message':
        iconData = Icons.chat_bubble_rounded;
        iconColor = theme.colorScheme.primary;
        break;
      case 'system':
        iconData = Icons.info_rounded;
        iconColor = theme.colorScheme.secondary;
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = theme.colorScheme.primary;
    }

    final timeStr = _formatTime(notification.createdAt);

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
        _notificationService.deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return DateFormat('yyyy/MM/dd').format(dateTime);
    }
  }
}
