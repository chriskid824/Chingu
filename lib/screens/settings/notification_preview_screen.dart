import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationPreviewScreen extends StatefulWidget {
  const NotificationPreviewScreen({super.key});

  @override
  State<NotificationPreviewScreen> createState() => _NotificationPreviewScreenState();
}

class _NotificationPreviewScreenState extends State<NotificationPreviewScreen> {
  // 0: Always Show, 1: Never
  int _selectedIndex = 0;

  void _showTestNotification() {
    final notification = NotificationModel(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      type: 'message',
      title: 'Chingu',
      message: _selectedIndex == 0 ? '哈囉！這週末有空一起吃飯嗎？' : '新訊息',
      createdAt: DateTime.now(),
      actionType: 'open_chat',
    );

    // 預覽時忽略用戶設定
    RichNotificationService().showNotification(notification, ignoreSettings: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('訊息預覽設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPreviewSection(theme, chinguTheme),
          const SizedBox(height: 24),
          _buildOptionsList(theme),
          const Spacer(),
           Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _showTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('發送測試通知'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme, ChinguTheme? chinguTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          Text(
            '預覽',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chingu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '現在',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedIndex == 0 ? '哈囉！這週末有空一起吃飯嗎？' : '新訊息',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(ThemeData theme) {
    return Column(
      children: [
        _buildOptionTile(
          theme: theme,
          title: '總是顯示',
          subtitle: '在通知中顯示訊息內容',
          index: 0,
        ),
        _buildOptionTile(
          theme: theme,
          title: '從不顯示',
          subtitle: '僅顯示「新訊息」',
          index: 1,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
