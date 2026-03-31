import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback? onLater;

  const NotificationPermissionDialog({
    super.key,
    required this.onEnable,
    this.onLater,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onEnable,
    VoidCallback? onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        onEnable: onEnable,
        onLater: onLater,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: chinguTheme?.shadowMedium ?? Colors.black12,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildIcon(theme, chinguTheme),
              const SizedBox(height: 24),
              Text(
                '開啟通知',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '不錯過任何重要訊息！\n即時收到配對成功、晚餐邀請和新訊息通知。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: '開啟通知',
                onPressed: () {
                  Navigator.of(context).pop();
                  onEnable();
                },
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLater?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, ChinguTheme? chinguTheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.1),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          final gradient = chinguTheme?.primaryGradient ??
              LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              );
          return gradient.createShader(bounds);
        },
        child: const Icon(
          Icons.notifications_active_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}
