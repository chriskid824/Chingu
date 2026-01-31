import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

enum RegistrationAction {
  register,
  waitlist,
  cancel,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationAction action;
  final String? eventTitle;
  final DateTime? eventDate;

  const EventRegistrationDialog({
    super.key,
    required this.action,
    this.eventTitle,
    this.eventDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RegistrationAction action,
    String? eventTitle,
    DateTime? eventDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        action: action,
        eventTitle: eventTitle,
        eventDate: eventDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String title;
    String message;
    String confirmText;
    Color confirmColor;
    IconData icon;

    switch (action) {
      case RegistrationAction.register:
        title = '確認報名';
        message = '確定要報名參加此活動嗎？報名後請務必準時出席。';
        confirmText = '確認報名';
        confirmColor = theme.colorScheme.primary;
        icon = Icons.check_circle_outline_rounded;
        break;
      case RegistrationAction.waitlist:
        title = '加入候補';
        message = '目前活動名額已滿。確定要加入候補名單嗎？若有空缺將自動遞補。';
        confirmText = '加入候補';
        confirmColor = chinguTheme?.warning ?? Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        break;
      case RegistrationAction.cancel:
        title = '取消報名';
        message = '確定要取消報名嗎？\n活動前 24 小時內取消將會影響您的信用評分。';
        confirmText = '確認取消';
        confirmColor = theme.colorScheme.error;
        icon = Icons.highlight_off_rounded;
        break;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Icon(
        icon,
        size: 48,
        color: confirmColor,
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (eventTitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    eventTitle!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (eventDate != null)
                    Text(
                      '${eventDate!.month}/${eventDate!.day} ${eventDate!.hour}:${eventDate!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '再想想',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
