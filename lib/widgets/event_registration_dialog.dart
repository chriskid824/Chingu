import 'package:flutter/material.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EventRegistrationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const EventRegistrationDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '確認',
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            if (onCancel != null) onCancel!();
          },
          child: const Text('取消', style: TextStyle(color: Colors.grey)),
        ),
        if (isDestructive)
          TextButton(
             onPressed: () {
               onConfirm();
               Navigator.of(context).pop(true);
             },
             child: Text(confirmText, style: const TextStyle(color: Colors.red)),
          )
        else
          SizedBox(
            width: 100,
            height: 40,
            child: GradientButton(
              text: confirmText,
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop(true);
              },
              borderRadius: 20,
            ),
          ),
      ],
    );
  }
}
