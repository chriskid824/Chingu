import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class NotificationPermissionDialog extends StatefulWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const NotificationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onDeny,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onAllow,
    required VoidCallback onDeny,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        onAllow: onAllow,
        onDeny: onDeny,
      ),
    );
  }

  @override
  State<NotificationPermissionDialog> createState() =>
      _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState
    extends State<NotificationPermissionDialog> {
  bool _canPop = false;

  void _handleClose(VoidCallback callback) {
    setState(() {
      _canPop = true;
    });
    // Ensure the widget rebuilds with _canPop = true before popping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
        callback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return PopScope(
      canPop: _canPop,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: chinguTheme?.shadowMedium ?? Colors.black12,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(context, chinguTheme, theme),
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
                '為了讓您不錯過任何配對成功、新訊息或活動提醒，請允許我們發送通知。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: '好的',
                onPressed: () => _handleClose(widget.onAllow),
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _handleClose(widget.onDeny),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('稍後再說'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    ChinguTheme? chinguTheme,
    ThemeData theme,
  ) {
    final icon = Icon(
      Icons.notifications_active_rounded,
      size: 48,
      color: Colors.white,
    );

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: chinguTheme?.primaryGradient ??
            LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (chinguTheme?.primaryGradient.colors.first ??
                    theme.colorScheme.primary)
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: icon),
    );
  }
}
