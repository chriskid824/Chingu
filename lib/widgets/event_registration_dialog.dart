import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final bool isRegistering; // true = register, false = cancel
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
    final isFull = event.isFull;

    String title = isRegistering ? '確認報名' : '取消報名';
    String message = '';

    if (isRegistering) {
      if (isFull) {
        message = '此活動人數已滿，您將被加入候補名單。如果有空位釋出，系統將自動為您遞補並發送通知。';
      } else {
        message = '您確定要報名此活動嗎？\n\n時間：${_formatDate(event.dateTime)}';
      }
    } else {
      // Check 24h
      final hoursUntil = event.dateTime.difference(DateTime.now()).inHours;
      if (hoursUntil < 24) {
        message = '活動即將開始（少於24小時）。取消可能會影響您的信用分數 (爽約/遲到)。您確定要取消嗎？';
      } else {
        message = '您確定要取消報名嗎？';
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('再想想'),
        ),
        if (isRegistering)
          SizedBox(
            width: 140,
            child: GradientButton(
              text: isFull ? '加入候補' : '確認報名',
              onPressed: onConfirm,
              height: 40,
              isLoading: isLoading,
            ),
          )
        else
          TextButton(
            onPressed: isLoading ? null : onConfirm,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('確認取消'),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
