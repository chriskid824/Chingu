import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final EventRegistrationStatus currentStatus;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.event,
    required this.currentStatus,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = event.isFull;

    String title;
    String content;
    String confirmText;
    Color confirmColor;
    bool isDestructive = false;

    switch (currentStatus) {
      case EventRegistrationStatus.registered:
        title = '取消報名';
        content = '您確定要取消報名此活動嗎？\n\n注意：活動開始前 24 小時內無法取消。頻繁取消可能會影響您的信用評分。';
        confirmText = '確認取消';
        confirmColor = theme.colorScheme.error;
        isDestructive = true;
        break;
      case EventRegistrationStatus.waitlist:
        title = '退出候補';
        content = '您確定要退出候補名單嗎？';
        confirmText = '退出候補';
        confirmColor = theme.colorScheme.error;
        isDestructive = true;
        break;
      case EventRegistrationStatus.cancelled:
      case EventRegistrationStatus.none:
        if (isFull) {
          title = '加入候補';
          content = '目前名額已滿。您想要加入候補名單嗎？\n\n如果有參與者退出，系統將自動為您遞補並發送通知。';
          confirmText = '加入候補';
          confirmColor = theme.colorScheme.primary;
        } else {
          title = '確認報名';
          content = '您確定要報名此活動嗎？\n\n活動時間：${event.dateTime.toString().substring(0, 16)}\n地點：${event.city}${event.district}';
          confirmText = '確認報名';
          confirmColor = theme.colorScheme.primary;
        }
        break;
    }

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: isLoading ? null : onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: confirmColor,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(confirmText),
        ),
      ],
    );
  }
}
