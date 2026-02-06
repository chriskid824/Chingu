import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dinner_event_model.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final bool isCancelling;

  const EventRegistrationDialog({
    Key? key,
    required this.event,
    this.isCancelling = false,
  }) : super(key: key);

  static Future<bool?> show(BuildContext context, {required DinnerEventModel event, bool isCancelling = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(event: event, isCancelling: isCancelling),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');
    final isOnWaitlist = event.isFull;

    String title = isCancelling ? '取消報名' : (isOnWaitlist ? '加入候補名單' : '確認報名');
    String contentText = isCancelling
        ? '您確定要取消報名嗎？\n\n注意：若在活動前 24 小時內取消，可能會影響您的信用評分。'
        : (isOnWaitlist
            ? '目前活動人數已滿，您將加入候補名單。\n若有名額釋出，系統將自動為您遞補並通知。'
            : '確定要參加這場晚餐聚會嗎？\n\n地點：${event.city} ${event.district}\n時間：${dateFormat.format(event.dateTime)}');

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contentText),
          if (!isCancelling && !isOnWaitlist) ...[
            const SizedBox(height: 16),
            const Text(
              '取消政策：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('活動前 24 小時可免費取消。之後取消或未出席將扣除信用積分。'),
          ],
          if (isOnWaitlist && !isCancelling) ...[
             const SizedBox(height: 16),
             Text('目前候補人數：${event.waitlist.length} 人'),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('再想想'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isCancelling ? Colors.red : null,
          ),
          child: Text(isCancelling ? '確認取消' : '確認'),
        ),
      ],
    );
  }
}
