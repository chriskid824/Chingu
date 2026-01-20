import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final storageService = NotificationStorageService();

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
          TextButton(
            onPressed: () async {
              await storageService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已全部標記為已讀')),
                );
              }
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
      body: StreamBuilder<List<NotificationModel>>(
        stream: storageService.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '載入失敗: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
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
              return _buildNotificationItem(context, notification, chinguTheme);
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

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ChinguTheme? chinguTheme,
  ) {
    final theme = Theme.of(context);
    final storageService = NotificationStorageService();

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
        icon = Icons.star_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) async {
        await storageService.deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(context, notification),
        child: Container(
          color: !notification.isRead
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: !notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
      BuildContext context, NotificationModel notification) async {
    final storageService = NotificationStorageService();

    // Mark as read
    if (!notification.isRead) {
      await storageService.markAsRead(notification.id);
    }

    if (!context.mounted) return;

    // Handle navigation
    if (notification.actionType != null) {
      switch (notification.actionType) {
        case 'open_chat':
          final otherUserId = notification.actionData;
          if (otherUserId != null && otherUserId.isNotEmpty) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final chatService = ChatService();
                final firestoreService = FirestoreService();

                final chatRoomId = await chatService.createChatRoom(
                    currentUser.uid, otherUserId);
                final otherUser = await firestoreService.getUser(otherUserId);

                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                }

                if (otherUser != null && context.mounted) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.chatDetail,
                    arguments: {
                      'chatRoomId': chatRoomId,
                      'otherUser': otherUser,
                    },
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading if error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('無法開啟聊天: $e')),
                  );
                }
              }
            }
          } else {
            Navigator.of(context).pushNamed(AppRoutes.chatList);
          }
          break;
        case 'view_event':
          Navigator.of(context).pushNamed(AppRoutes.eventDetail);
          break;
        case 'match':
          Navigator.of(context).pushNamed(AppRoutes.matchesList);
          break;
        case 'view_match':
          Navigator.of(context).pushNamed(AppRoutes.matchesList);
          break;
        default:
          break;
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${time.year}/${time.month}/${time.day}';
    }
  }
}
