import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum RegistrationAction {
  join,
  joinWaitlist,
  leave,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationAction action;
  final String eventTitle;
  final DateTime eventDate;
  final VoidCallback onConfirm;
  final bool isProcessing;

  const EventRegistrationDialog({
    super.key,
    required this.action,
    required this.eventTitle,
    required this.eventDate,
    required this.onConfirm,
    this.isProcessing = false,
  });

  static Future<void> show(
    BuildContext context, {
    required RegistrationAction action,
    required String eventTitle,
    required DateTime eventDate,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EventRegistrationDialog(
        action: action,
        eventTitle: eventTitle,
        eventDate: eventDate,
        onConfirm: onConfirm,
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
    Color? confirmColor;
    List<Color>? confirmGradient;

    switch (action) {
      case RegistrationAction.join:
        title = '確認報名';
        message = '您即將報名參加「$eventTitle」。\n活動時間：${_formatDate(eventDate)}\n\n請確認您當天可以準時出席。';
        confirmText = '確認報名';
        confirmGradient = chinguTheme?.primaryGradient;
        break;
      case RegistrationAction.joinWaitlist:
        title = '加入候補';
        message = '目前活動名額已滿。\n是否加入候補名單？\n\n如果有空位釋出，我們將自動為您遞補並發送通知。';
        confirmText = '加入候補';
        confirmGradient = chinguTheme?.secondaryGradient;
        break;
      case RegistrationAction.leave:
        title = '取消報名';
        message = '您確定要取消報名嗎？\n\n注意：活動前 24 小時內無法取消。頻繁取消可能會影響您的信用評分。';
        confirmText = '確認取消';
        confirmColor = theme.colorScheme.error;
        break;
      case RegistrationAction.leaveWaitlist:
        title = '取消候補';
        message = '您確定要退出候補名單嗎？';
        confirmText = '退出候補';
        confirmColor = theme.colorScheme.error;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '再考慮',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: confirmGradient != null
                        ? GradientButton(
                            text: confirmText,
                            onPressed: () {
                              onConfirm();
                              Navigator.of(context).pop();
                            },
                            gradient: LinearGradient(colors: confirmGradient),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              onConfirm();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(confirmText),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
