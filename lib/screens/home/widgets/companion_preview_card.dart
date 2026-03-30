import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/widgets/geometric_avatar.dart';

/// 狀態 3：部分解鎖 — 飯友輪廓列表（幾何頭像 + 星座/產業/年齡段）
class CompanionPreviewCard extends StatelessWidget {
  final DinnerGroupModel group;
  final String currentUserId;

  const CompanionPreviewCard({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final companions = group.companionPreviews;
    final otherCount = group.participantIds.length - 1;

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
          color: AppColorsMinimal.primary.withValues(alpha: 0.2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColorsMinimal.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_rounded,
                  color: AppColorsMinimal.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppColorsMinimal.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '你的飯友來了',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$otherCount 位神秘飯友等你發現',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColorsMinimal.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 飯友輪廓列表
          if (companions.isNotEmpty)
            ...companions.asMap().entries.map(
              (entry) => _buildCompanionTile(entry.key, entry.value),
            )
          else
            // fallback：沒有 companionPreviews 時用 participantIds 數量顯示
            ...List.generate(
              otherCount.clamp(0, 6),
              (i) => _buildPlaceholderTile(i),
            ),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 餐廳保密提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppColorsMinimal.spaceMD),
            decoration: BoxDecoration(
              color: AppColorsMinimal.primaryBackground,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock_rounded, size: 16, color: AppColorsMinimal.primary),
                const SizedBox(width: 6),
                Text(
                  '餐廳地址將於週三 17:00 揭曉',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColorsMinimal.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 有 companionPreviews 資料的飯友卡
  Widget _buildCompanionTile(int index, Map<String, dynamic> preview) {
    final color = GeometricAvatar.colors[index % GeometricAvatar.colors.length];
    final icon = GeometricAvatar.icons[index % GeometricAvatar.icons.length];
    final zodiac = preview['zodiac'] as String? ?? '?';
    final industry = preview['industryCategory'] as String? ?? '?';
    final ageGroup = preview['ageGroup'] as String? ?? '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceSM),
      padding: const EdgeInsets.all(AppColorsMinimal.spaceMD),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Row(
        children: [
          // 幾何頭像
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppColorsMinimal.spaceMD),
          // 資訊 chips
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildChip(zodiac),
                _buildChip(industry),
                _buildChip(ageGroup),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 沒有 companionPreviews 時的 placeholder
  Widget _buildPlaceholderTile(int index) {
    final color = GeometricAvatar.colors[index % GeometricAvatar.colors.length];
    final icon = GeometricAvatar.icons[index % GeometricAvatar.icons.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceSM),
      padding: const EdgeInsets.all(AppColorsMinimal.spaceMD),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppColorsMinimal.spaceMD),
          Text(
            '神秘飯友 #${index + 1}',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColorsMinimal.textSecondary,
        ),
      ),
    );
  }
}
