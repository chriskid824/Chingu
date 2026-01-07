import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class NotificationsScreenDemo extends StatelessWidget {
  const NotificationsScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text(
          '通知',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              '全部已讀',
              style: TextStyle(
                color: AppColorsMinimal.primary,
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
            Icons.favorite_rounded,
            AppColorsMinimal.error,
            '王小華 喜歡了您的個人資料',
            '2 小時前',
            isUnread: true,
          ),
          _buildNotificationItem(
            Icons.chat_bubble_rounded,
            AppColorsMinimal.primary,
            '李小美 傳送了一則訊息給您',
            '3 小時前',
            isUnread: true,
          ),
          _buildNotificationItem(
            Icons.event_available_rounded,
            AppColorsMinimal.success,
            '您與 陳大明 的晚餐預約已確認',
            '昨天',
            isUnread: false,
          ),
          _buildNotificationItem(
            Icons.stars_rounded,
            AppColorsMinimal.warning,
            '恭喜！您獲得了新的成就徽章',
            '2 天前',
            isUnread: false,
          ),
          _buildNotificationItem(
            Icons.person_add_rounded,
            AppColorsMinimal.secondary,
            '林小芳 想要與您配對',
            '3 天前',
            isUnread: false,
          ),
          _buildNotificationItem(
            Icons.restaurant_rounded,
            AppColorsMinimal.primary,
            '本週三晚餐報名即將截止',
            '4 天前',
            isUnread: false,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem(
    IconData icon,
    Color color,
    String message,
    String time, {
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? AppColorsMinimal.primaryBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColorsMinimal.primary.withOpacity(0.2)
              : AppColorsMinimal.surfaceVariant,
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
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.primaryGradient,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
