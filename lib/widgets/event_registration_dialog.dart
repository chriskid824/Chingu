import 'package:flutter/material.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/core/theme/app_theme.dart';

enum RegistrationAction {
  join,
  joinWaitlist,
  leave,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationAction action;
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.action,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color actionColor;
    String buttonText;

    switch (action) {
      case RegistrationAction.join:
        actionColor = theme.colorScheme.primary;
        buttonText = '確認報名';
        break;
      case RegistrationAction.joinWaitlist:
        actionColor = chinguTheme?.warning ?? Colors.orange;
        buttonText = '加入候補';
        break;
      case RegistrationAction.leave:
      case RegistrationAction.leaveWaitlist:
        actionColor = theme.colorScheme.error;
        buttonText = '確認取消';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
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
                _getIcon(action),
                size: 32,
                color: actionColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  GradientButton(
                    text: buttonText,
                    onPressed: onConfirm,
                    gradient: action == RegistrationAction.leave || action == RegistrationAction.leaveWaitlist
                        ? LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)])
                        : null, // Use default for join
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      '再考慮一下',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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

  IconData _getIcon(RegistrationAction action) {
    switch (action) {
      case RegistrationAction.join:
        return Icons.check_circle_outline_rounded;
      case RegistrationAction.joinWaitlist:
        return Icons.hourglass_empty_rounded;
      case RegistrationAction.leave:
      case RegistrationAction.leaveWaitlist:
        return Icons.warning_amber_rounded;
    }
  }
}
