import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class NotificationPermissionDialog extends StatefulWidget {
  const NotificationPermissionDialog({super.key});

  /// Shows the permission dialog and returns true if permission was granted,
  /// false if denied or dismissed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NotificationPermissionDialog(),
    );
    return result ?? false;
  }

  @override
  State<NotificationPermissionDialog> createState() => _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState extends State<NotificationPermissionDialog> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (mounted) {
        Navigator.of(context).pop(granted);
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      if (mounted) {
        // In case of error, we just close the dialog returning false
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '開啟通知',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '即時接收配對成功、新訊息以及活動更新。我們會妥善控制通知頻率。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: '開啟通知',
              onPressed: _requestPermission,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '暫不開啟',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
