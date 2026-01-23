import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/notification_model.dart';
import '../core/theme/app_theme.dart';
import '../core/routes/app_router.dart';

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

  /// 顯示應用內通知橫幅
  static void show({
    required NotificationModel notification,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = AppRouter.navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationOverlay(
        notification: notification,
        onTap: onTap,
        onRemoveEntry: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        duration: duration,
      ),
    );

    overlayState.insert(overlayEntry);
  }

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

class _InAppNotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback onRemoveEntry;
  final Duration duration;

  const _InAppNotificationOverlay({
    required this.notification,
    this.onTap,
    required this.onRemoveEntry,
    required this.duration,
  });

  @override
  State<_InAppNotificationOverlay> createState() => _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<_InAppNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _controller.reverse();
    widget.onRemoveEntry();
  }

  void _handleTap() async {
    if (_isDismissing) return;
    _isDismissing = true;
    widget.onTap?.call();
    await _controller.reverse();
    widget.onRemoveEntry();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _animation,
        child: InAppNotification(
          notification: widget.notification,
          onTap: _handleTap,
          onDismiss: _dismiss,
        ),
      ),
    );
  }
}
