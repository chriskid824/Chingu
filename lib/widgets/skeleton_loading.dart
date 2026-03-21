import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

/// 通用 Shimmer 載入佔位元件
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColorsMinimal.surfaceVariant,
      highlightColor: AppColorsMinimal.background,
      child: child,
    );
  }
}

/// 首頁倒數卡的 Skeleton
class HomeCardSkeleton extends StatelessWidget {
  const HomeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
        decoration: BoxDecoration(
          color: AppColorsMinimal.surface,
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        ),
        child: Column(
          children: [
            // 圓環佔位
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorsMinimal.surfaceVariant,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceLG),
            // Info chips 佔位
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(),
                const SizedBox(width: AppColorsMinimal.spaceMD),
                _chip(),
                const SizedBox(width: AppColorsMinimal.spaceMD),
                _chip(),
              ],
            ),
            const SizedBox(height: AppColorsMinimal.spaceLG),
            // 文案佔位
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: AppColorsMinimal.surfaceVariant,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chip() {
    return Container(
      width: 80,
      height: 28,
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
      ),
    );
  }
}

/// 聊天列表的 Skeleton
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => _buildRow(),
      ),
    );
  }

  static Widget _buildRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 頭像
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColorsMinimal.surfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.surfaceVariant,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
