import 'package:flutter/material.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const EventRegistrationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '確認',
    this.cancelText = '取消',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop(true);
          },
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = '確認',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        confirmText: confirmText,
        isDestructive: isDestructive,
      ),
    );
  }
}
