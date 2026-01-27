import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

enum InAppNotificationType {
  success,
  error,
  warning,
  info,
  standard,
}

class InAppNotification extends StatelessWidget {
  final String title;
  final String message;
  final InAppNotificationType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    super.key,
    required this.title,
    required this.message,
    this.type = InAppNotificationType.standard,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Fallback colors if theme extension is not available
    final successColor = chinguTheme?.success ?? Colors.green;
    final errorColor = chinguTheme?.error ?? Colors.red;
    final warningColor = chinguTheme?.warning ?? Colors.orange;
    final infoColor = chinguTheme?.info ?? Colors.blue;
    final standardColor = theme.colorScheme.primary;

    Color typeColor;
    IconData iconData;

    switch (type) {
      case InAppNotificationType.success:
        typeColor = successColor;
        iconData = Icons.check_circle_outline;
        break;
      case InAppNotificationType.error:
        typeColor = errorColor;
        iconData = Icons.error_outline;
        break;
      case InAppNotificationType.warning:
        typeColor = warningColor;
        iconData = Icons.warning_amber_rounded;
        break;
      case InAppNotificationType.info:
        typeColor = infoColor;
        iconData = Icons.info_outline;
        break;
      case InAppNotificationType.standard:
        typeColor = standardColor;
        iconData = Icons.notifications_none_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowMedium ?? Colors.black12,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Dismiss Button
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDismiss,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
