import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _notificationService = NotificationStorageService();

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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.watchUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: () => _notificationService.markAllAsRead(),
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
        stream: _notificationService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('通知已刪除'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: _buildNotificationItem(context, notification),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

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

    // Determine icon and color based on type
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
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
    }

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _notificationService.markAsRead(notification.id);
        }
        if (mounted) {
           _handleNavigation(notification);
        }
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
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
    );
  }

  Future<void> _handleNavigation(NotificationModel notification) async {
    if (notification.actionType == null) return;

    // Check authentication
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    switch (notification.actionType) {
      case 'open_chat':
        if (notification.actionData != null) {
          final otherUserId = notification.actionData!;

          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // Find or create chat room using ChatService
            final chatRoomId = await ChatService().createChatRoom(currentUser.uid, otherUserId);

            // Fetch other user details
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

            if (mounted) {
              Navigator.pop(context); // Dismiss loading

              if (userDoc.exists) {
                final otherUser = UserModel.fromMap(
                  userDoc.data() as Map<String, dynamic>,
                  userDoc.id,
                );

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
                  const SnackBar(content: Text('無法找到用戶')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // Dismiss loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('錯誤: $e')),
              );
            }
          }
        }
        break;

      case 'view_event':
        if (notification.actionData != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {'eventId': notification.actionData},
          );
        }
        break;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return '昨天';
      if (diff.inDays < 7) return '${diff.inDays} 天前';
      return DateFormat('yyyy/MM/dd').format(dateTime);
    } else if (diff.inHours > 0) {
      return '${diff.inHours} 小時前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
}
