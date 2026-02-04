import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum RegistrationDialogType {
  join,
  waitlist,
  cancel,
  leaveWaitlist,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationDialogType type;
  final String eventName;
  final String eventDate;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.type,
    required this.eventName,
    required this.eventDate,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String title;
    String content;
    String confirmText;
    LinearGradient? confirmGradient;

    switch (type) {
      case RegistrationDialogType.join:
        title = '確認報名';
        content = '確定要報名 $eventName 嗎？\n時間：$eventDate\n\n報名後請務必準時出席。';
        confirmText = '確認報名';
        confirmGradient = chinguTheme?.primaryGradient;
        break;
      case RegistrationDialogType.waitlist:
        title = '加入候補';
        content = '目前活動人數已滿。確定要加入候補名單嗎？\n\n如果有位子釋出，您將自動遞補並收到通知。';
        confirmText = '加入候補';
        confirmGradient = chinguTheme?.warningGradient;
        break;
      case RegistrationDialogType.cancel:
        title = '取消報名';
        content = '確定要取消報名嗎？\n\n如果在活動開始前 24 小時內取消，可能會扣除信用點數。';
        confirmText = '確認取消';
        confirmGradient = chinguTheme?.errorGradient;
        break;
      case RegistrationDialogType.leaveWaitlist:
        title = '退出候補';
        content = '確定要退出候補名單嗎？';
        confirmText = '退出候補';
        confirmGradient = chinguTheme?.errorGradient;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), // Match GradientButton default height approx
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('再想想'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: confirmText,
                    onPressed: onConfirm,
                    gradient: confirmGradient,
                    isLoading: isLoading,
                    height: 52, // Slightly smaller than default 56 to fit nicely
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
