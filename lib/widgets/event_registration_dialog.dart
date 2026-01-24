import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive; // 用於紅色按鈕 (例如取消報名)

  const EventRegistrationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = '確認',
    this.cancelText = '取消',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(cancelText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
