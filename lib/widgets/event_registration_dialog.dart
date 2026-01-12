import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum EventActionType {
  join,
  joinWaitlist,
  cancel,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final EventActionType actionType;
  final String eventTitle;
  final String? waitlistPosition;
  final VoidCallback onConfirm;

  const EventRegistrationDialog({
    super.key,
    required this.actionType,
    required this.eventTitle,
    this.waitlistPosition,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required EventActionType actionType,
    required String eventTitle,
    String? waitlistPosition,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        actionType: actionType,
        eventTitle: eventTitle,
        waitlistPosition: waitlistPosition,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String title;
    String content;
    String buttonText;
    Color? buttonColor;
    Gradient? buttonGradient;

    switch (actionType) {
      case EventActionType.join:
        title = '確認報名';
        content = '您即將報名「$eventTitle」。\n\n請確保您能準時出席，爽約將會扣除信用積分。';
        buttonText = '確認報名';
        buttonGradient = chinguTheme?.primaryGradient;
        break;
      case EventActionType.joinWaitlist:
        title = '加入候補';
        content = '目前活動已滿員，您將加入候補名單。\n\n如果有位子釋出，系統將自動為您報名並發送通知。';
        buttonText = '加入候補';
        buttonGradient = chinguTheme?.secondaryGradient;
        break;
      case EventActionType.cancel:
        title = '取消報名';
        content = '您確定要取消報名嗎？\n\n如果在活動開始前24小時內取消，將會扣除信用積分。';
        buttonText = '確認取消';
        buttonColor = theme.colorScheme.error;
        break;
      case EventActionType.leaveWaitlist:
        title = '取消候補';
        content = '您確定要退出候補名單嗎？';
        buttonText = '確認退出';
        buttonColor = theme.colorScheme.error;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            if (waitlistPosition != null && actionType == EventActionType.leaveWaitlist) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '目前候補順位: $waitlistPosition',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '再考慮一下',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buttonGradient != null
                      ? GradientButton(
                          text: buttonText,
                          onPressed: onConfirm,
                          height: 48,
                          gradient: buttonGradient,
                        )
                      : ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
