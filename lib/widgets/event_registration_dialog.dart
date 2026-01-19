import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';

class EventRegistrationDialog extends StatelessWidget {
  final EventRegistrationStatus currentStatus;
  final bool isFull;
  final int waitlistCount;
  final DateTime eventDate;

  const EventRegistrationDialog({
    super.key,
    required this.currentStatus,
    required this.isFull,
    required this.waitlistCount,
    required this.eventDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required EventRegistrationStatus currentStatus,
    required bool isFull,
    required int waitlistCount,
    required DateTime eventDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        currentStatus: currentStatus,
        isFull: isFull,
        waitlistCount: waitlistCount,
        eventDate: eventDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String message;
    String buttonText;
    bool isDestructive = false;

    switch (currentStatus) {
      case EventRegistrationStatus.registered:
        title = '取消報名';
        message = '您確定要取消報名嗎？\n\n活動開始前 24 小時內無法取消。取消後如果活動已滿，將無法重新報名。';
        buttonText = '確認取消';
        isDestructive = true;
        break;
      case EventRegistrationStatus.waitlist:
        title = '退出候補';
        message = '您確定要退出候補名單嗎？';
        buttonText = '確認退出';
        isDestructive = true;
        break;
      case EventRegistrationStatus.none:
      default:
        if (isFull) {
          title = '加入候補';
          message = '目前活動名額已滿。\n\n目前候補人數：$waitlistCount 人\n\n若有參加者取消，系統將自動依序遞補並通知您。';
          buttonText = '加入候補';
        } else {
          title = '報名活動';
          message = '確定要報名此活動嗎？\n\n報名後請務必準時出席。若需取消，請於活動 24 小時前操作。';
          buttonText = '確認報名';
        }
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive ? Icons.warning_rounded : Icons.calendar_today_rounded,
                color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '再考慮一下',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: buttonText,
                    onPressed: () => Navigator.of(context).pop(true),
                    gradient: isDestructive
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.error,
                              theme.colorScheme.error.withOpacity(0.8),
                            ],
                          )
                        : null,
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
