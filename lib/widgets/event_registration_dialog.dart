import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

enum RegistrationDialogType {
  register,
  joinWaitlist,
  cancel,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationDialogType type;
  final String? eventTitle;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.type,
    this.eventTitle,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String title;
    String message;
    String confirmText;
    Color? iconColor;
    IconData icon;

    switch (type) {
      case RegistrationDialogType.register:
        title = '確認報名';
        message = '您即將報名此活動。報名後請務必準時出席，以免影響您的信用評分。';
        confirmText = '確認報名';
        iconColor = chinguTheme?.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case RegistrationDialogType.joinWaitlist:
        title = '加入候補';
        message = '目前活動已滿，您將加入候補名單。若有空位釋出，系統將自動為您遞補並發送通知。';
        confirmText = '加入候補';
        iconColor = chinguTheme?.warning;
        icon = Icons.hourglass_empty_rounded;
        break;
      case RegistrationDialogType.cancel:
        title = '取消報名';
        message = '您確定要取消報名嗎？活動開始前 24 小時內不可取消。頻繁取消可能會影響您的信用評分。';
        confirmText = '確認取消';
        iconColor = theme.colorScheme.error;
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '再想想',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: confirmText,
                    onPressed: isLoading ? null : onConfirm,
                    isLoading: isLoading,
                    gradient: type == RegistrationDialogType.cancel
                        ? LinearGradient(colors: [
                            theme.colorScheme.error.withOpacity(0.8),
                            theme.colorScheme.error,
                          ])
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
