import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final bool isRegistering; // true = register, false = cancel
  final VoidCallback onConfirm;

  const EventRegistrationDialog({
    super.key,
    required this.event,
    required this.isRegistering,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final isWithin24Hours = event.dateTime.difference(DateTime.now()).inHours < 24;
    final isFull = event.isFull;

    return AlertDialog(
      title: Text(isRegistering
        ? (isFull ? '加入等候清單' : '確認報名')
        : '取消報名'
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRegistering) ...[
             Text('活動時間: ${event.dateTime.toString().substring(0, 16)}'),
             const SizedBox(height: 8),
             if (isFull)
               Text(
                 '目前活動已滿員，您將被加入等候清單。若有人取消，系統將自動遞補您並通知。',
                 style: TextStyle(color: chinguTheme?.warning),
               )
             else
               const Text('確定要報名參加這場晚餐聚會嗎？'),
          ] else ...[
            if (isWithin24Hours)
              Text(
                '警告：活動將在24小時內開始。現在無法取消報名。',
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
              )
            else
              const Text('確定要取消報名嗎？若有等候者將會自動遞補。'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('返回'),
        ),
        if (isRegistering || !isWithin24Hours)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isRegistering
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isRegistering ? '確認' : '取消報名'),
          ),
      ],
    );
  }
}
