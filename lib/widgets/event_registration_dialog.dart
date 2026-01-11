import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/enums/event_registration_status.dart';

class EventRegistrationDialog extends StatelessWidget {
  final EventRegistrationStatus status;
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.status,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.isLoading = false,
  });

  static Future<void> show({
    required BuildContext context,
    required EventRegistrationStatus status,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) async {
    String title;
    String content;

    switch (status) {
      case EventRegistrationStatus.registered:
        title = '確認報名';
        content = '您確定要報名此活動嗎？\n\n報名後若要取消，請於活動前24小時操作。';
        break;
      case EventRegistrationStatus.waitlist:
        title = '加入候補';
        content = '此活動人數已滿。\n\n您確定要加入候補名單嗎？若有名額釋出，將自動遞補並通知您。';
        break;
      case EventRegistrationStatus.cancelled:
        title = '取消報名';
        content = '您確定要取消報名嗎？';
        break;
      default:
        title = '提示';
        content = '';
    }

    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => EventRegistrationDialog(
        status: status,
        title: title,
        content: content,
        onConfirm: onConfirm,
        isLoading: isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '再想想',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(
              '確定',
              style: TextStyle(
                color: status == EventRegistrationStatus.cancelled
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
