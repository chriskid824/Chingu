import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/screens/home/widgets/countdown_ring.dart';

/// 狀態 2：配對中 — 脈衝動畫邀請卡 + 倒數圓環
class MatchingCard extends StatefulWidget {
  final DinnerEventModel? event;

  const MatchingCard({super.key, this.event});

  @override
  State<MatchingCard> createState() => _MatchingCardState();
}

class _MatchingCardState extends State<MatchingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsMinimal.surface,
            AppColorsMinimal.primaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.surfaceVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowMedium,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 倒數圓環
          if (widget.event != null)
            CountdownRing(
              targetDate: widget.event!.eventDate,
              size: 160,
              strokeWidth: 8,
            )
          else
            const SizedBox(height: 160),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 脈衝動畫文案
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '最佳飯友匹配中...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorsMinimal.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceMD),

          // 已報名提示
          if (widget.event != null)
            _buildInfoChip(Icons.check_circle_rounded, '已報名 ✓'),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 保密提示
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.spaceLG,
              vertical: AppColorsMinimal.spaceSM,
            ),
            decoration: BoxDecoration(
              color: AppColorsMinimal.primaryBackground,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColorsMinimal.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '驚喜地點倒數揭曉中',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColorsMinimal.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColorsMinimal.spaceMD,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColorsMinimal.success),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
