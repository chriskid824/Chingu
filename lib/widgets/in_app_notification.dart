import 'dart:async';
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
        return chinguTheme.error;
      case 'event':
        return theme.colorScheme.primary;
      case 'message':
        return chinguTheme.info;
      case 'rating':
        return chinguTheme.warning;
      case 'system':
      default:
        return chinguTheme.success;
    }
  }
}

class InAppNotificationUtils {
  static OverlayEntry? _overlayEntry;

  /// 顯示應用內通知
  static void show(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 如果已有通知，先移除 (無動畫，直接替換)
    _removeCurrentNotification();

    final overlayState = Overlay.of(context, rootOverlay: true);

    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _InAppNotificationContainer(
        notification: notification,
        duration: duration,
        onTap: () {
          _removeCurrentNotification();
          onTap?.call();
        },
        onDismiss: _removeCurrentNotification,
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// 移除當前通知
  static void _removeCurrentNotification() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}

class _InAppNotificationContainer extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _InAppNotificationContainer({
    required this.notification,
    required this.duration,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_InAppNotificationContainer> createState() => _InAppNotificationContainerState();
}

class _InAppNotificationContainerState extends State<_InAppNotificationContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // 啟動自動消失計時器
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Align(
          alignment: Alignment.topCenter,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: InAppNotification(
              notification: widget.notification,
              onDismiss: _dismiss,
              onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }
}
