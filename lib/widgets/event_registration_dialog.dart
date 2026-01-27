import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const EventRegistrationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = '取消',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
