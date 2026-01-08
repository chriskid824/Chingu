import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

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
          TextButton(
            onPressed: () {},
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildNotificationItem(
            context,
            Icons.favorite_rounded,
            theme.colorScheme.error,
            '王小華 喜歡了您的個人資料',
            '2 小時前',
            isUnread: true,
            onTap: () => NotificationService.instance.handleNotificationClick(
              NotificationModel(
                id: '1',
                userId: 'user1',
                type: 'match',
                title: 'New Like',
                message: '王小華 喜歡了您的個人資料',
                createdAt: DateTime.now(),
                actionType: 'open_match',
                actionData: 'user_123',
              ),
            ),
          ),
          _buildNotificationItem(
            context,
            Icons.chat_bubble_rounded,
            theme.colorScheme.primary,
            '李小美 傳送了一則訊息給您',
            '3 小時前',
            isUnread: true,
            onTap: () => NotificationService.instance.handleNotificationClick(
              NotificationModel(
                id: '2',
                userId: 'user1',
                type: 'message',
                title: 'New Message',
                message: '李小美 傳送了一則訊息給您',
                createdAt: DateTime.now(),
                actionType: 'open_chat',
                actionData: 'room_123',
              ),
            ),
          ),
          _buildNotificationItem(
            context,
            Icons.event_available_rounded,
            chinguTheme?.success ?? Colors.green,
            '您與 陳大明 的晚餐預約已確認',
            '昨天',
            isUnread: false,
            onTap: () => NotificationService.instance.handleNotificationClick(
              NotificationModel(
                id: '3',
                userId: 'user1',
                type: 'event',
                title: 'Event Confirmed',
                message: '您與 陳大明 的晚餐預約已確認',
                createdAt: DateTime.now(),
                actionType: 'open_event',
                actionData: 'event_123',
              ),
            ),
          ),
          _buildNotificationItem(
            context,
            Icons.stars_rounded,
            chinguTheme?.warning ?? Colors.amber,
            '恭喜！您獲得了新的成就徽章',
            '2 天前',
            isUnread: false,
            onTap: () {}, // System notification, no navigation
          ),
          _buildNotificationItem(
            context,
            Icons.person_add_rounded,
            chinguTheme?.secondary ?? Colors.purple,
            '林小芳 想要與您配對',
            '3 天前',
            isUnread: false,
            onTap: () => NotificationService.instance.handleNotificationClick(
              NotificationModel(
                id: '5',
                userId: 'user1',
                type: 'match',
                title: 'New Match Request',
                message: '林小芳 想要與您配對',
                createdAt: DateTime.now(),
                actionType: 'open_match',
              ),
            ),
          ),
          _buildNotificationItem(
            context,
            Icons.restaurant_rounded,
            theme.colorScheme.primary,
            '本週三晚餐報名即將截止',
            '4 天前',
            isUnread: false,
            onTap: () => NotificationService.instance.handleNotificationClick(
              NotificationModel(
                id: '6',
                userId: 'user1',
                type: 'event',
                title: 'Event Reminder',
                message: '本週三晚餐報名即將截止',
                createdAt: DateTime.now(),
                actionType: 'open_event',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    Color color,
    String message,
    String time, {
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return GestureDetector(
      onTap: onTap,
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
          message,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            time,
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
        ),
      ),
    );
  }
}
