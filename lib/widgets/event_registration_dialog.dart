import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final bool isRegistering;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.event,
    required this.isRegistering,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = event.participantIds.length >= event.maxParticipants;
    final isWaitlist = isRegistering && isFull;

    return AlertDialog(
      title: Text(
        isRegistering
          ? (isWaitlist ? '加入等候名單' : '確認報名')
          : '取消報名',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRegistering) ...[
              Text('您即將報名參加以下活動：', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.calendar_today,
                DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime)),
              const SizedBox(height: 8),
              _buildDetailRow(context, Icons.location_on, event.restaurantName ?? '${event.city}${event.district}'),
              const SizedBox(height: 8),
              _buildDetailRow(context, Icons.attach_money, event.budgetRangeText),

              const SizedBox(height: 16),
              if (isWaitlist)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '目前活動已滿員，您將被加入等候名單。若有名額釋出，系統將自動通知遞補。',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '注意事項：',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• 活動前 24 小時內取消將會扣除信用積分。\n• 請確保準時出席，無故缺席將嚴重影響信用等級。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
               Text('您確定要取消報名嗎？', style: theme.textTheme.bodyMedium),
               const SizedBox(height: 16),
               Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getCancellationMessage(),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: isLoading ? null : onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: isRegistering ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              )
            : Text(isRegistering ? (isWaitlist ? '加入等候' : '確認報名') : '確認取消'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _getCancellationMessage() {
    return '您確定要取消報名嗎？取消後名額將由候補者遞補。';
  }
}
