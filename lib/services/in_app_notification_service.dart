import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/in_app_notification.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import 'rich_notification_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();

  factory InAppNotificationService() {
    return _instance;
  }

  InAppNotificationService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _timer;

  /// 顯示應用內通知
  void show(NotificationModel notification) {
    // 如果已有通知顯示中，先移除
    hide();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildNotification(context, notification),
    );

    overlayState.insert(_overlayEntry!);

    // 4秒後自動消失
    _timer = Timer(const Duration(seconds: 4), () {
      hide();
    });
  }

  /// 隱藏當前通知
  void hide() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildNotification(BuildContext context, NotificationModel notification) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: const Offset(0, -1), end: const Offset(0, 0)),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, offset, child) {
            return FractionalTranslation(
              translation: offset,
              child: child,
            );
          },
          child: InAppNotification(
            notification: notification,
            onDismiss: hide,
            onTap: () {
              hide();
              RichNotificationService().handleNavigation(
                notification.actionType,
                notification.actionData,
                null,
              );
            },
          ),
        ),
      ),
    );
  }
}
