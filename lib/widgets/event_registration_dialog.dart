import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

enum RegistrationAction {
  join,
  waitlist,
  cancel,
}

class EventRegistrationDialog extends StatelessWidget {
  final RegistrationAction action;
  final String? title;
  final String? message;
  final VoidCallback onConfirm;
  final bool isLoading;

  const EventRegistrationDialog({
    super.key,
    required this.action,
    this.title,
    this.message,
    required this.onConfirm,
    this.isLoading = false,
  });

  factory EventRegistrationDialog.join({
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return EventRegistrationDialog(
      action: RegistrationAction.join,
      title: '確認報名',
      message: '確定要報名參加此晚餐活動嗎？\n報名成功後，請務必準時出席。',
      onConfirm: onConfirm,
      isLoading: isLoading,
    );
  }

  factory EventRegistrationDialog.waitlist({
    required int currentWaitlistCount,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return EventRegistrationDialog(
      action: RegistrationAction.waitlist,
      title: '加入等候清單',
      message: '目前名額已滿。\n是否加入等候清單？\n目前前方還有 $currentWaitlistCount 位在等候中。',
      onConfirm: onConfirm,
      isLoading: isLoading,
    );
  }

  factory EventRegistrationDialog.cancel({
    required bool isWithin24Hours,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return EventRegistrationDialog(
      action: RegistrationAction.cancel,
      title: '取消報名',
      message: isWithin24Hours
          ? '⚠️ 距離活動開始已不足 24 小時。\n現在取消將會記錄一次爽約，並扣除信用積分。\n確定要取消嗎？'
          : '確定要取消報名嗎？\n取消後，名額將會釋出給等候名單的成員。',
      onConfirm: onConfirm,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color actionColor;
    String confirmText;
    IconData icon;

    switch (action) {
      case RegistrationAction.join:
        actionColor = chinguTheme?.success ?? Colors.green;
        confirmText = '確認報名';
        icon = Icons.check_circle_outline_rounded;
        break;
      case RegistrationAction.waitlist:
        actionColor = theme.colorScheme.primary;
        confirmText = '加入等候';
        icon = Icons.hourglass_empty_rounded;
        break;
      case RegistrationAction.cancel:
        actionColor = theme.colorScheme.error;
        confirmText = '確認取消';
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: actionColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? '',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            confirmText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
