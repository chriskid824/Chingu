import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum EventRegistrationAction {
  register,
  joinWaitlist,
  cancelRegistration,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String message;
  final EventRegistrationAction action;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const EventRegistrationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.action,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required EventRegistrationAction action,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: title,
        message: message,
        action: action,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color actionColor;
    String actionText;
    IconData actionIcon;

    switch (action) {
      case EventRegistrationAction.register:
        actionColor = theme.colorScheme.primary;
        actionText = '確認報名';
        actionIcon = Icons.check_circle_rounded;
        break;
      case EventRegistrationAction.joinWaitlist:
        actionColor = chinguTheme?.warning ?? Colors.orange;
        actionText = '加入候補';
        actionIcon = Icons.access_time_filled_rounded;
        break;
      case EventRegistrationAction.cancelRegistration:
      case EventRegistrationAction.leaveWaitlist:
        actionColor = theme.colorScheme.error;
        actionText = '確認取消';
        actionIcon = Icons.cancel_rounded;
        break;
    }

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon,
                size: 32,
                color: actionColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (onCancel != null) onCancel!();
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '再考慮一下',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: actionText,
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop(true);
                    },
                    colors: action == EventRegistrationAction.cancelRegistration ||
                           action == EventRegistrationAction.leaveWaitlist
                        ? [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)]
                        : (action == EventRegistrationAction.joinWaitlist
                            ? [chinguTheme?.warning ?? Colors.orange, (chinguTheme?.warning ?? Colors.orange).withOpacity(0.8)]
                            : null), // Default primary gradient
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
