import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';

class EventRegistrationDialog extends StatelessWidget {
  final DinnerEventModel event;
  final EventRegistrationStatus currentStatus;
  final VoidCallback onConfirm;
  final bool isProcessing;

  const EventRegistrationDialog({
    Key? key,
    required this.event,
    required this.currentStatus,
    required this.onConfirm,
    this.isProcessing = false,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required DinnerEventModel event,
    required EventRegistrationStatus currentStatus,
    required VoidCallback onConfirm,
    bool isProcessing = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        event: event,
        currentStatus: currentStatus,
        onConfirm: onConfirm,
        isProcessing: isProcessing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>()!;

    String title = '';
    String message = '';
    String confirmText = '';
    bool isDestructive = false;

    // Determine content based on status and event state
    if (currentStatus == EventRegistrationStatus.registered) {
      // Cancel registration
      title = '取消報名';
      confirmText = '確認取消';
      isDestructive = true;

      final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
      if (hoursUntilEvent < 24) {
        message = '活動開始前 24 小時內不可取消。如未出席將會被記錄爽約 (No-show)，並扣除信用積分。';
      } else {
        message = '您確定要取消報名嗎？如果在活動開始前 24 小時內取消或未出席，將會影響您的信用積分。';
      }
    } else if (currentStatus == EventRegistrationStatus.waitlist) {
      // Leave waitlist
      title = '退出候補';
      message = '您確定要退出候補名單嗎？退出後如果要重新加入將需要重新排隊。';
      confirmText = '退出候補';
      isDestructive = true;
    } else {
      // Join (Register or Waitlist)
      if (event.isFull) {
        title = '加入候補名單';
        message = '目前活動名額已滿。您確定要加入候補名單嗎？如果有參與者退出，系統將自動依序遞補並通知您。';
        confirmText = '加入候補';
      } else {
        title = '確認報名';
        message = '您確定要報名參加此活動嗎？\n\n時間：${event.dateTime.toString().substring(0, 16)}\n地點：${event.city} ${event.district}';
        confirmText = '確認報名';
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
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
                      '再想想',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: confirmText,
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop(true);
                    },
                    gradient: isDestructive
                        ? LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.error])
                        : chinguTheme.primaryGradient,
                    isLoading: isProcessing,
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
