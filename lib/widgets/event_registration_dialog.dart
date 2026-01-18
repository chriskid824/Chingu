import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

enum RegistrationDialogType {
  register,
  joinWaitlist,
  cancel,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationDialogType type;
  final DinnerEventModel event;
  final VoidCallback onConfirm;

  const EventRegistrationDialog({
    super.key,
    required this.type,
    required this.event,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required RegistrationDialogType type,
    required DinnerEventModel event,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        type: type,
        event: event,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String title = '';
    String content = '';
    String confirmText = '';
    Color confirmColor = theme.colorScheme.primary;
    bool isDestructive = false;
    bool canAction = true;

    switch (type) {
      case RegistrationDialogType.register:
        title = '確認報名';
        content = '確定要報名 ${DateFormat('MM/dd').format(event.dateTime)} 的晚餐聚會嗎？\n\n報名後請務必準時出席，以免影響他人權益。';
        confirmText = '確認報名';
        break;
      case RegistrationDialogType.joinWaitlist:
        title = '加入候補';
        content = '目前活動名額已滿，確定要加入候補名單嗎？\n\n若有人取消，系統將自動為您遞補並發送通知。';
        confirmText = '加入候補';
        confirmColor = chinguTheme?.warning ?? Colors.orange;
        break;
      case RegistrationDialogType.cancel:
        title = '取消報名';
        content = '確定要取消報名嗎？\n\n活動開始前 24 小時內取消將會影響您的信用評分。';
        confirmText = '確認取消';
        confirmColor = theme.colorScheme.error;
        isDestructive = true;

        // 檢查是否在24小時內
        final timeUntilEvent = event.dateTime.difference(DateTime.now());
        if (timeUntilEvent.inHours < 24) {
          content = '⚠️ 注意：活動即將在 24 小時內開始。\n\n根據規定，活動前 24 小時內無法線上取消報名。如遇緊急狀況，請直接聯繫客服人員處理。';
          canAction = false;
        }
        break;
    }

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (canAction)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('再想想'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),

        if (canAction)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: confirmColor,
            ),
            child: Text(confirmText),
          ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
