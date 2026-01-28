import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final String? tooltip;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 24,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed == null ? null : () {
          HapticFeedback.selectionClick();
          onPressed!();
        },
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
