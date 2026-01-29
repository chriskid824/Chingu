import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final String currentUserId;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isParticipant = event.participantIds.contains(currentUserId);
    final isWaitlisted = event.waitingListIds.contains(currentUserId);
    final isFull = event.isFull;

    String title;
    String content;
    String confirmText;
    Color confirmColor;

    if (isParticipant) {
      title = '取消報名';
      content = '您確定要取消報名此活動嗎？\n\n注意：如果您在活動開始前 24 小時內取消，將會扣除信用點數。';
      confirmText = '確認取消';
      confirmColor = Colors.red;
    } else if (isWaitlisted) {
      title = '退出等候名單';
      content = '您確定要退出此活動的等候名單嗎？';
      confirmText = '退出';
      confirmColor = Colors.red;
    } else if (isFull) {
      title = '加入等候名單';
      content = '目前活動名額已滿。您想要加入等候名單嗎？\n\n如果有參與者退出，您將有機會自動遞補加入。';
      confirmText = '加入等候';
      confirmColor = Theme.of(context).colorScheme.primary;
    } else {
      title = '確認報名';
      final formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(event.dateTime);
      content = '您確定要報名此活動嗎？\n\n時間：$formattedDate\n地點：${event.city}${event.district}';
      confirmText = '確認報名';
      confirmColor = Theme.of(context).colorScheme.primary;
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
