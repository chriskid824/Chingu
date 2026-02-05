import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  // 暫時使用本地數據，後續可改為從 Provider 或 API 獲取
  List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      userId: 'current_user',
      type: 'match',
      title: '王小華 喜歡了您的個人資料',
      message: '王小華 喜歡了您的個人資料',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      actionType: 'match_history',
    ),
    NotificationModel(
      id: '2',
      userId: 'current_user',
      type: 'message',
      title: '李小美 傳送了一則訊息給您',
      message: '李小美 傳送了一則訊息給您',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      actionType: 'open_chat',
    ),
    NotificationModel(
      id: '3',
      userId: 'current_user',
      type: 'event',
      title: '您與 陳大明 的晚餐預約已確認',
      message: '您與 陳大明 的晚餐預約已確認',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      actionType: 'view_event',
    ),
    NotificationModel(
      id: '4',
      userId: 'current_user',
      type: 'rating',
      title: '恭喜！您獲得了新的成就徽章',
      message: '恭喜！您獲得了新的成就徽章',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      userId: 'current_user',
      type: 'match',
      title: '林小芳 想要與您配對',
      message: '林小芳 想要與您配對',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      actionType: 'match_history',
    ),
    NotificationModel(
      id: '6',
      userId: 'current_user',
      type: 'event',
      title: '本週三晚餐報名即將截止',
      message: '本週三晚餐報名即將截止',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
      actionType: 'view_event',
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.markAsRead()).toList();
    });
  }

  void _handleNotificationTap(NotificationModel notification) {
    // 標記為已讀
    if (!notification.isRead) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.markAsRead();
        }
      });
    }

    // 處理導航
    if (notification.actionType != null) {
      final navigator = Navigator.of(context);
      switch (notification.actionType) {
        case 'open_chat':
          navigator.pushNamed(AppRoutes.chatList);
          break;
        case 'view_event':
          // 這裡假設跳轉到活動列表，如果有 eventId 可跳轉到詳情
          navigator.pushNamed(AppRoutes.eventsList);
          break;
        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;
        default:
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
        centerTitle: true,
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
      body: _notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(context, _notifications[index]);
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

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
  ) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // 根據類型決定圖標和顏色
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'match':
        icon = Icons.favorite_rounded;
        color = theme.colorScheme.error;
        break;
      case 'match_request':
        icon = Icons.person_add_rounded;
        color = chinguTheme?.secondary ?? Colors.purple;
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'event':
        icon = Icons.event_available_rounded;
        color = chinguTheme?.success ?? Colors.green;
        break;
      case 'event_reminder':
        icon = Icons.restaurant_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'rating':
        icon = Icons.stars_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      default:
        // Fallback 邏輯
        if (notification.title.contains('配對')) {
          icon = Icons.person_add_rounded;
          color = chinguTheme?.secondary ?? Colors.purple;
        } else if (notification.title.contains('晚餐')) {
          icon = Icons.restaurant_rounded;
          color = theme.colorScheme.primary;
        } else {
          icon = Icons.notifications_rounded;
          color = theme.colorScheme.primary;
        }
    }

    // 格式化時間
    final diff = DateTime.now().difference(notification.createdAt);
    String timeStr;
    if (diff.inHours < 24) {
      timeStr = '${diff.inHours} 小時前';
      if (diff.inHours == 0) timeStr = '${diff.inMinutes} 分鐘前';
    } else {
      timeStr = '${diff.inDays} 天前';
      if (diff.inDays == 1) timeStr = '昨天';
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeStr,
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
        ),
      ),
    );
  }
}
