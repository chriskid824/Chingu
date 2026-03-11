import 'package:flutter/material.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/widgets/in_app_notification.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _storageService.watchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '通知',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
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
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '載入通知失敗',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: '沒有新通知',
              description: '您目前沒有任何通知消息',
              iconColor: theme.colorScheme.primary,
              spacing: 24,
            );
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
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  _storageService.deleteNotification(notification.id);
                },
                child: InAppNotification(
                  notification: notification,
                  onTap: () async {
                    if (!notification.isRead) {
                      await _storageService.markAsRead(notification.id);
                    }
                    _richNotificationService.handleNotificationTap(
                      notification.actionType,
                      notification.actionData,
                      null,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
