import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum EventActionType {
  join,
  cancel,
  joinWaitlist,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final EventActionType type;
  final String title;
  final String content;
  final VoidCallback onConfirm;

  const EventRegistrationDialog({
    super.key,
    required this.type,
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: _getColor(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 32,
                color: _getColor(context),
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
              content,
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
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: '確認',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    gradient: type == EventActionType.cancel || type == EventActionType.leaveWaitlist
                        ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700])
                        : null, // Default gradient
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    switch (type) {
      case EventActionType.join:
        return chinguTheme?.success ?? Colors.green;
      case EventActionType.joinWaitlist:
        return chinguTheme?.warning ?? Colors.orange;
      case EventActionType.cancel:
      case EventActionType.leaveWaitlist:
        return theme.colorScheme.error;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case EventActionType.join:
        return Icons.check_circle_outline_rounded;
      case EventActionType.joinWaitlist:
        return Icons.hourglass_empty_rounded;
      case EventActionType.cancel:
      case EventActionType.leaveWaitlist:
        return Icons.warning_amber_rounded;
    }
  }
}
