import 'package:flutter/material.dart';
import 'package:chingu/utils/haptic_utils.dart';

class AppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? color;
  final double? iconSize;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final String? tooltip;
  final Widget? selectedIcon;
  final bool? isSelected;
  final ButtonStyle? style;

  const AppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.iconSize,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = Alignment.center,
    this.tooltip,
    this.selectedIcon,
    this.isSelected,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticUtils.light();
              onPressed!();
            },
      icon: icon,
      color: color,
      iconSize: iconSize,
      padding: padding,
      alignment: alignment,
      tooltip: tooltip,
      selectedIcon: selectedIcon,
      isSelected: isSelected,
      style: style,
    );
  }
}
