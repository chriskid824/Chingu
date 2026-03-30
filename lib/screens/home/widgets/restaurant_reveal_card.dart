import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_group_model.dart';

/// 狀態 4：完全解鎖 — 餐廳資訊卡 + 地圖導航 + 破冰話題入口
class RestaurantRevealCard extends StatelessWidget {
  final DinnerGroupModel group;

  const RestaurantRevealCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final chinguTheme = Theme.of(context).extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: chinguTheme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.primary.withValues(alpha: 0.3),
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
          // 解鎖圖示
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: chinguTheme?.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),

          Text(
            '餐廳已揭曉！',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXL),

          // 餐廳資訊卡
          _buildRestaurantInfo(),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 導航按鈕
          if (group.restaurantAddress != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMapNavigation(),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('導航前往'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsMinimal.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          const SizedBox(height: AppColorsMinimal.spaceMD),

          // 破冰話題入口
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.icebreaker,
                  arguments: {'groupId': group.id},
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('查看破冰話題'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsMinimal.secondary,
                side: BorderSide(
                  color: AppColorsMinimal.secondary.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    final name = group.restaurantName ?? '餐廳資訊載入中';
    final address = group.restaurantAddress ?? '';
    final phone = group.restaurantPhone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 餐廳名稱
          Row(
            children: [
              Icon(
                Icons.restaurant_rounded,
                size: 18,
                color: AppColorsMinimal.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (address.isNotEmpty) ...[
            const SizedBox(height: AppColorsMinimal.spaceSM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColorsMinimal.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColorsMinimal.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: AppColorsMinimal.spaceSM),
            Row(
              children: [
                Icon(
                  Icons.phone_rounded,
                  size: 16,
                  color: AppColorsMinimal.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColorsMinimal.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppColorsMinimal.spaceMD),

          // 聚餐人數 + 時間
          Row(
            children: [
              _buildTag(Icons.people_rounded, '${group.participantIds.length} 人'),
              const SizedBox(width: 8),
              _buildTag(Icons.access_time_rounded, '19:00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColorsMinimal.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapNavigation() async {
    final address = group.restaurantAddress ?? '';
    if (address.isEmpty) return;

    // 優先用 GeoPoint，沒有就用地址搜尋
    final lat = group.restaurantLocation?.latitude;
    final lng = group.restaurantLocation?.longitude;

    final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
