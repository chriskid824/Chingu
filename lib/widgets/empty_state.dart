import 'package:flutter/material.dart';

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

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconSize = 80.0,
    required this.title,
    this.description,
    this.actionLabel,
    this.onActionPressed,
    this.customAction,
    this.spacing = 16.0,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface.withOpacity(0.2);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
            if (customAction != null || (actionLabel != null && onActionPressed != null)) ...[
              SizedBox(height: spacing * 1.5),
              customAction ??
                  ElevatedButton(
                    onPressed: onActionPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
