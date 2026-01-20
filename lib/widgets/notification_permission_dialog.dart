import 'package:flutter/material.dart';
import '../services/rich_notification_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onAllowed;
  final VoidCallback? onDenied;
  final bool requestPermissionOnAllow;

  const NotificationPermissionDialog({
    super.key,
    this.onAllowed,
    this.onDenied,
    this.requestPermissionOnAllow = true,
  });

  Future<void> _handleAllow(BuildContext context) async {
    // 關閉對話框
    Navigator.of(context).pop();

    if (requestPermissionOnAllow) {
      // 請求權限
      await RichNotificationService().requestPermissions();
    }

    // 執行回調
    onAllowed?.call();
  }

  void _handleDeny(BuildContext context) {
    Navigator.of(context).pop();
    onDenied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon / Illustration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              '開啟通知',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              '為了讓您不錯過任何配對成功、聊天訊息與聚餐提醒，我們建議您開啟通知權限。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleDeny(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '暫時不要',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAllow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '開啟通知',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 靜態方法用於方便呼叫
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAllowed,
    VoidCallback? onDenied,
    bool requestPermissionOnAllow = true,
  }) {
    return showDialog(
      context: context,
      builder: (context) => NotificationPermissionDialog(
        onAllowed: onAllowed,
        onDenied: onDenied,
        requestPermissionOnAllow: requestPermissionOnAllow,
      ),
    );
  }
}
