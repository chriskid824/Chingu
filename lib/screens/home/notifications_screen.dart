import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 暫時使用本地數據，後續可改為從 Provider 或 API 獲取
  // 將此列表設為空即可測試空狀態
  List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      userId: 'current_user',
      type: 'match',
      title: '王小華 喜歡了您的個人資料',
      message: '王小華 喜歡了您的個人資料',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      deeplink: '/profile/user1',
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      userId: 'current_user',
      type: 'message',
      title: '李小美 傳送了一則訊息給您',
      message: '李小美 傳送了一則訊息給您',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      deeplink: '/chat/detail',
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      userId: 'current_user',
      type: 'event',
      title: '您與 陳大明 的晚餐預約已確認',
      message: '您與 陳大明 的晚餐預約已確認',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      deeplink: '/event/detail',
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      userId: 'current_user',
      type: 'rating',
      title: '恭喜！您獲得了新的成就徽章',
      message: '恭喜！您獲得了新的成就徽章',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      deeplink: '/profile/achievements',
      isRead: true,
    ),
    // 為了區分 "喜歡" 和 "配對請求"，這裡我們可能需要更細的類型，但目前暫用 match
    // 並依賴 title 或 message 來區分在實際後端邏輯中應該是不同的 type
    // 為了演示目的，這裡保持使用 match，但在 UI 渲染時我們會根據上下文處理
    NotificationModel(
      id: '5',
      userId: 'current_user',
      type: 'match',
      title: '林小芳 想要與您配對',
      message: '林小芳 想要與您配對',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      deeplink: '/match/requests',
      isRead: true,
    ),
    NotificationModel(
      id: '6',
      userId: 'current_user',
      type: 'event',
      title: '本週三晚餐報名即將截止',
      message: '本週三晚餐報名即將截止',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      deeplink: '/event/list',
      isRead: true,
    ),
  ];

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
              onPressed: () {
                setState(() {
                  // 標記所有為已讀
                  // 這裡只是模擬，實際應呼叫 API
                  _notifications =
                      _notifications.map((n) => n.markAsRead()).toList();
                });
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
      body: _notifications.isEmpty
          ? Center(
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
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _notifications.map((notification) {
                return _buildNotificationItem(
                  context,
                  notification,
                );
              }).toList(),
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

    // 簡單映射，實際專案應定義更多 type
    switch (notification.type) {
      case 'match':
        icon = Icons.favorite_rounded;
        color = theme.colorScheme.error;
        break;
      case 'match_request': // 假設新增此類型對應 "想要與您配對"
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
      case 'event_reminder': // 假設新增此類型對應 "晚餐報名截止"
        icon = Icons.restaurant_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'rating':
        icon = Icons.stars_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      default:
        // 如果是 match 但 title 包含 "配對" (fallback for existing data)
        if (notification.type == 'match' && notification.title.contains('配對')) {
          icon = Icons.person_add_rounded;
          color = chinguTheme?.secondary ?? Colors.purple;
        } else if (notification.type == 'event' &&
            notification.title.contains('晚餐')) {
          icon = Icons.restaurant_rounded;
          color = theme.colorScheme.primary;
        } else {
          icon = Icons.notifications_rounded;
          color = theme.colorScheme.primary;
        }
    }

    // 格式化時間 (簡單模擬)
    final diff = DateTime.now().difference(notification.createdAt);
    String timeStr;
    if (diff.inHours < 24) {
      timeStr = '${diff.inHours} 小時前';
      if (diff.inHours == 0) timeStr = '${diff.inMinutes} 分鐘前';
    } else {
      timeStr = '${diff.inDays} 天前';
      if (diff.inDays == 1) timeStr = '昨天';
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
    );
  }
}
