import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/notification_model.dart';
import '../core/theme/app_theme.dart';

class InAppNotification extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const InAppNotification({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Determine icon color based on type
    final iconColor = _getIconColor(notification.type, chinguTheme, theme);
    final iconData = _getIconData(notification.iconName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
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
                border: Border.all(
                  color: chinguTheme?.surfaceVariant ?? Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar or Icon
                  _buildLeading(iconData, iconColor, chinguTheme),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(IconData iconData, Color iconColor, ChinguTheme? chinguTheme) {
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: chinguTheme?.surfaceVariant ?? Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: notification.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200],
            ),
            errorWidget: (context, url, error) => Container(
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200],
              child: Icon(iconData, color: iconColor, size: 20),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'favorite': return Icons.favorite_rounded;
      case 'event': return Icons.calendar_today_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'star': return Icons.star_rounded;
      case 'notifications':
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type, ChinguTheme? chinguTheme, ThemeData theme) {
    if (chinguTheme == null) return theme.colorScheme.primary;

    switch (type) {
      case 'match':
        return chinguTheme.error; // Pink/Red for love/match
      case 'event':
        return theme.colorScheme.primary;
      case 'message':
        return chinguTheme.info;
      case 'rating':
        return chinguTheme.warning;
      case 'system':
      default:
        return chinguTheme.success; // Or primary
    }
  }
}
