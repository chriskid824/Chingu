import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();

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
          StreamBuilder<List<NotificationModel>>(
            stream: _storageService.watchNotifications(limit: 1),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  await _storageService.markAllAsRead();
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
        stream: _storageService.watchNotifications(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '載入通知失敗',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
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
                    '目前沒有任何通知消息',
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(
                context,
                notification,
                chinguTheme,
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
    ChinguTheme? chinguTheme,
  ) {
    final theme = Theme.of(context);

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
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
        break;
    }

    final timeStr = _getRelativeTime(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _storageService.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(context, notification),
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
                  : chinguTheme?.surfaceVariant ?? theme.dividerColor,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                fontWeight:
                    !notification.isRead ? FontWeight.w600 : FontWeight.normal,
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
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
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

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _storageService.markAsRead(notification.id);
    }

    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final actionType = notification.actionType;
    final actionData = notification.actionData;

    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          // actionData should be the other user's ID
          if (actionData != null && actionData.isNotEmpty) {
            try {
              // Show loading dialog if needed, or just let the user wait a bit
              // For better UX, we could show a progress indicator

              final authProvider = context.read<AuthProvider>();
              final currentUserId = authProvider.uid;

              if (currentUserId == null) {
                 navigator.pushNamed(AppRoutes.login);
                 return;
              }

              final otherUser = await _firestoreService.getUser(actionData);
              if (otherUser != null) {
                 // Get or create chat room
                 final chatRoomId = await _chatService.createChatRoom(currentUserId, actionData);

                 if (context.mounted) {
                   navigator.pushNamed(
                     AppRoutes.chatDetail,
                     arguments: {
                       'chatRoomId': chatRoomId,
                       'otherUser': otherUser,
                     },
                   );
                 }
              } else {
                 // User not found, fallback to chat list
                 navigator.pushNamed(AppRoutes.chatList);
              }
            } catch (e) {
              // Handle error, maybe show snackbar?
              debugPrint('Error navigating to chat: $e');
              navigator.pushNamed(AppRoutes.chatList);
            }
          } else {
             navigator.pushNamed(AppRoutes.chatList);
          }
          break;
        case 'view_event':
          navigator.pushNamed(AppRoutes.eventDetail);
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
          break;
      }
    }
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return '剛剛';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${diff.inDays ~/ 7} 週前';
    }
  }
}
