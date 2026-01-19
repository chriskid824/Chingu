import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  /// 顯示通知權限請求對話框
  /// 返回 true 表示用戶點擊了"立即開啟"
  /// 返回 false 表示用戶點擊了"稍後再說"或關閉了對話框
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 強制用戶做出選擇
      builder: (context) => const NotificationPermissionDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            // Icon with Gradient
            _buildGradientIcon(context, chinguTheme),
            const SizedBox(height: 24),
            // Title
            Text(
              '開啟通知',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              '第一時間收到晚餐配對邀請、聊天訊息和活動提醒。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientButton(
                  text: '立即開啟',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '稍後再說',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildGradientIcon(BuildContext context, ChinguTheme? chinguTheme) {
    final theme = Theme.of(context);

    Widget icon = Icon(
      Icons.notifications_active_rounded,
      size: 64,
      color: theme.colorScheme.primary,
    );

    if (chinguTheme != null) {
      return ShaderMask(
        shaderCallback: (bounds) {
          return chinguTheme.primaryGradient.createShader(bounds);
        },
        child: Icon(
          Icons.notifications_active_rounded,
          size: 64,
          color: Colors.white, // Color is ignored by ShaderMask but required
        ),
      );
    }

    return icon;
  }
}
