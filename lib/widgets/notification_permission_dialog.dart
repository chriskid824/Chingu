import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const NotificationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onDeny,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAllow,
    required VoidCallback onDeny,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        onAllow: onAllow,
        onDeny: onDeny,
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
              _buildIcon(context, chinguTheme),
              const SizedBox(height: 24),
              Text(
                'Stay Connected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enable notifications to get updates on new matches, messages, and upcoming events. Don\'t miss out on the action!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Turn on Notifications',
                onPressed: () {
                  Navigator.of(context).pop();
                  onAllow();
                },
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDeny();
                },
                child: Text(
                  'Not Now',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, ChinguTheme? chinguTheme) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) {
            return (chinguTheme?.primaryGradient ??
                    LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary
                      ],
                    ))
                .createShader(bounds);
          },
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
