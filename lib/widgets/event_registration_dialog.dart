import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final String currentUserId;
  final bool isRegistered;
  final bool isWaitlisted;
  final Function() onConfirm;

  const EventRegistrationDialog({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.isRegistered,
    required this.isWaitlisted,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final isFull = event.isFull;
    final now = DateTime.now();
    final hoursUntilEvent = event.dateTime.difference(now).inHours;
    final isTooLateToCancel = hoursUntilEvent < 24;

    String title;
    String message;
    String confirmText;
    Color confirmColor;
    bool isDestructive = false;

    if (isRegistered) {
      title = '取消報名';
      if (isTooLateToCancel) {
        message = '活動即將開始（24小時內），無法取消報名。如無法出席將會被記錄缺席。';
        confirmText = '無法取消';
        confirmColor = Colors.grey;
      } else {
        message = '您確定要取消報名嗎？如果有候補人員將會自動遞補。';
        confirmText = '確認取消';
        confirmColor = theme.colorScheme.error;
        isDestructive = true;
      }
    } else if (isWaitlisted) {
      title = '退出候補';
      message = '您確定要退出候補名單嗎？';
      confirmText = '退出候補';
      confirmColor = theme.colorScheme.error;
      isDestructive = true;
    } else {
      // Joining
      if (isFull) {
        title = '加入候補名單';
        message = '目前活動名額已滿。您確定要加入候補名單嗎？若有人取消，系統將自動為您遞補並發送通知。';
        confirmText = '加入候補';
        confirmColor = chinguTheme?.warning ?? Colors.orange;
      } else {
        title = '確認報名';
        message = '您確定要報名此活動嗎？活動開始前 24 小時內不可取消。';
        confirmText = '確認報名';
        confirmColor = chinguTheme?.success ?? Colors.green;
      }
    }

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '取消',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: (isRegistered && isTooLateToCancel)
              ? null
              : () {
                  onConfirm();
                  Navigator.of(context).pop(true);
                },
          style: TextButton.styleFrom(
            foregroundColor: confirmColor,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: (isRegistered && isTooLateToCancel) ? Colors.grey : confirmColor,
            ),
          ),
        ),
      ],
    );
  }
}
