import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/geometric_avatar.dart';

/// 狀態 5：待評價 — 飯友頭像列 + CTA 跳轉 ReviewScreen
class PendingReviewCard extends StatelessWidget {
  final DinnerGroupModel group;
  final String currentUserId;

  const PendingReviewCard({
    super.key,
    required this.group,
    required this.currentUserId,
  });


  @override
  Widget build(BuildContext context) {
    final otherIds = group.participantIds
        .where((id) => id != currentUserId)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.secondary.withValues(alpha: 0.3),
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
          // 圖標
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColorsMinimal.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_rounded,
              color: AppColorsMinimal.secondary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),

          Text(
            '昨晚的晚餐如何？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '為你的飯友留下評價，也許會解鎖新朋友',
            style: TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textSecondary,
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 飯友頭像列
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: otherIds.asMap().entries.map((entry) {
              final i = entry.key;
              final color = GeometricAvatar.colors[i % GeometricAvatar.colors.length];
              final icon = GeometricAvatar.icons[i % GeometricAvatar.icons.length];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              );
            }).toList(),
          ),

          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '${otherIds.length} 位飯友等你評價',
            style: TextStyle(
              fontSize: 12,
              color: AppColorsMinimal.textTertiary,
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 倒數提示
          _buildDeadlineHint(),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // CTA 按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final reviewProvider = context.read<ReviewProvider>();
                final userId = authProvider.uid;
                if (userId == null) return;

                // 載入待評價群組，取得含 pendingReviewees 的完整 Map
                await reviewProvider.loadPendingReviews(userId);
                if (!context.mounted) return;

                // 找到與本 group 匹配的待評價群組
                final matchingGroup = reviewProvider.pendingGroups
                    .where((g) => g['groupId'] == group.id)
                    .toList();

                if (matchingGroup.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.review,
                    arguments: {'group': matchingGroup.first},
                  );
                } else {
                  // fallback: 用 DinnerGroupModel 建構 Map
                  Navigator.pushNamed(
                    context,
                    AppRoutes.review,
                    arguments: {
                      'group': {
                        'groupId': group.id,
                        'eventId': group.eventId,
                        'memberIds': group.participantIds,
                        'pendingReviewees': otherIds,
                      },
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                elevation: 0,
              ),
              child: const Text(
                '為飯友評價',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineHint() {
    // 評價截止 = 活動後 72 小時（週一 10:00 自動跳過）
    // 這裡簡單用 group.createdAt + 5 天估算（週四晚到週一早）
    final deadline = group.createdAt.add(const Duration(days: 4, hours: 14));
    final remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      return const SizedBox.shrink();
    }

    final text = remaining.inHours < 24
        ? '剩餘 ${remaining.inHours} 小時'
        : '剩餘 ${remaining.inDays} 天';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColorsMinimal.spaceLG,
        vertical: AppColorsMinimal.spaceSM,
      ),
      decoration: BoxDecoration(
        color: remaining.inHours < 24
            ? AppColorsMinimal.errorLight
            : AppColorsMinimal.warningLight,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 14,
            color: remaining.inHours < 24
                ? AppColorsMinimal.error
                : AppColorsMinimal.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '評價截止倒數 $text',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: remaining.inHours < 24
                  ? AppColorsMinimal.error
                  : AppColorsMinimal.warning,
            ),
          ),
        ],
      ),
    );
  }
}
