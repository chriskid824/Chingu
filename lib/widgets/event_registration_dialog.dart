import 'package:flutter/material.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const EventRegistrationDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = '確認',
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
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
}
