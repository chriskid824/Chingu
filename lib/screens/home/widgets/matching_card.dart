import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/screens/home/widgets/countdown_ring.dart';

/// 狀態 2：配對中 — 精緻電子邀請卡 + 微光邊框 + 倒數圓環
class MatchingCard extends StatefulWidget {
  final DinnerEventModel? event;

  const MatchingCard({super.key, this.event});

  @override
  State<MatchingCard> createState() => _MatchingCardState();
}

class _MatchingCardState extends State<MatchingCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // 脈衝動畫（文字呼吸）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 邊框微光旋轉動畫
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG + 2),
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: math.pi * 2,
              transform: GradientRotation(_shimmerController.value * math.pi * 2),
              colors: const [
                AppColorsMinimal.surfaceVariant,
                AppColorsMinimal.fabStart,
                AppColorsMinimal.secondary,
                AppColorsMinimal.fabEnd,
                AppColorsMinimal.surfaceVariant,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(1.5),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColorsMinimal.surface,
              AppColorsMinimal.primaryBackground.withValues(alpha: 0.6),
              AppColorsMinimal.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        ),
        child: Column(
          children: [
            // 頂部標籤
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColorsMinimal.spaceLG,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.accentGradient,
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
              ),
              child: const Text(
                'YOUR DINNER INVITATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: AppColorsMinimal.spaceXL),

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
                  _buildPulseDot(),
                  const SizedBox(width: AppColorsMinimal.spaceSM),
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
              _buildInfoChip(Icons.check_circle_rounded, '已報名'),

            const SizedBox(height: AppColorsMinimal.spaceLG),

            // 分隔線
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.space2XL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColorsMinimal.border.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppColorsMinimal.spaceLG),

            // 保密提示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPulseDot() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColorsMinimal.secondary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColorsMinimal.secondary.withValues(
                  alpha: 0.4 * _pulseAnimation.value,
                ),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColorsMinimal.spaceMD,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColorsMinimal.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
        border: Border.all(
          color: AppColorsMinimal.success.withValues(alpha: 0.3),
        ),
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
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.success,
            ),
          ),
        ],
      ),
    );
  }
}
