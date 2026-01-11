import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final double iconSize;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Widget? customAction;
  final double spacing;
  final bool useGradientBackground;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconSize = 64.0,
    required this.title,
    this.description,
    this.actionLabel,
    this.onActionPressed,
    this.customAction,
    this.spacing = 24.0,
    this.useGradientBackground = false,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    Widget buildIcon() {
      if (iconWidget != null) return iconWidget!;
      return Icon(
        icon,
        size: iconSize,
        color: effectiveIconColor,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (useGradientBackground)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: buildIcon(),
              )
            else
              buildIcon(),
            SizedBox(height: spacing),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ],
            if (customAction != null || (actionLabel != null && onActionPressed != null)) ...[
              SizedBox(height: spacing * 1.5),
              customAction ??
                  GradientButton(
                    text: actionLabel!,
                    onPressed: onActionPressed!,
                    width: null, // Auto width
                    height: 48,
                    borderRadius: 24, // Pill shape
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
