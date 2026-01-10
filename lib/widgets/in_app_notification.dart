import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/notification_model.dart';
import '../core/theme/app_theme.dart';

/// InAppNotification Widget
///
/// Displays a top banner notification with a specific style based on the notification type.
/// Supports tapping to action and dismissing.
class InAppNotification extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotification({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>() ?? ChinguTheme.minimal;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: chinguTheme.shadowMedium,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading Icon/Avatar
                    _buildLeading(context, chinguTheme),
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
                    const SizedBox(width: 8),
                    // Dismiss Button
                    if (onDismiss != null)
                      InkWell(
                        onTap: onDismiss,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, ChinguTheme chinguTheme) {
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: chinguTheme.surfaceVariant,
        backgroundImage: CachedNetworkImageProvider(notification.imageUrl!),
      );
    }

    // Fallback Icon based on type
    LinearGradient gradient;
    IconData iconData;
    Color iconColor = Colors.white; // Default for gradient background

    switch (notification.type) {
      case 'match':
        gradient = chinguTheme.primaryGradient;
        iconData = Icons.favorite;
        break;
      case 'event':
        gradient = chinguTheme.secondaryGradient;
        iconData = Icons.event;
        break;
      case 'message':
        gradient = LinearGradient(colors: [chinguTheme.info, chinguTheme.info.withOpacity(0.8)]);
        iconData = Icons.chat_bubble;
        break;
      case 'rating':
        gradient = LinearGradient(colors: [chinguTheme.warning, chinguTheme.warning.withOpacity(0.8)]);
        iconData = Icons.star;
        break;
      case 'system':
      default:
        gradient = LinearGradient(colors: [chinguTheme.surfaceVariant, chinguTheme.surfaceVariant]);
        iconData = Icons.notifications;
        iconColor = Theme.of(context).colorScheme.onSurface; // Dark icon for light background
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
