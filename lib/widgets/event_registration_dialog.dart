import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final IconData? icon;

  const EventRegistrationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = '確認',
    this.cancelText = '取消',
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    gradient: isDestructive
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.error,
                              theme.colorScheme.error.withOpacity(0.8),
                            ],
                          )
                        : null,
                    height: 44,
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
