import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AvatarBadge extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool isOnline;
  final VoidCallback? onTap;
  final bool showOfflineBadge;
  final Color? borderColor;

  const AvatarBadge({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.isOnline = false,
    this.onTap,
    this.showOfflineBadge = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final badgeSize = radius * 0.6; // Scale badge relative to avatar
    final borderSize = 2.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chinguTheme?.surfaceVariant ?? Colors.grey[200],
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(
                        Icons.person,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        size: radius,
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        size: radius,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      size: radius,
                    ),
            ),
          ),

          // Status Badge
          if (isOnline || showOfflineBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: isOnline
                      ? (chinguTheme?.success ?? Colors.green)
                      : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor ?? theme.scaffoldBackgroundColor,
                    width: borderSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
