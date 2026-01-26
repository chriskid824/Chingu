import 'package:flutter/material.dart';
import '../services/rich_notification_service.dart';
import '../core/theme/app_theme.dart';
import 'gradient_button.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Icon with background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              '不錯過任何精彩時刻',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Body
            Text(
              '開啟通知，第一時間收到配對成功、好友訊息及晚餐聚會提醒。我們承諾不會發送垃圾訊息。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Actions
            GradientButton(
              text: '開啟通知',
              onPressed: () async {
                final granted = await RichNotificationService().requestPermissions();
                if (context.mounted) {
                  Navigator.of(context).pop(granted);
                }
              },
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: const Text('暫不開啟'),
            ),
          ],
        ),
      ),
    );
  }
}
