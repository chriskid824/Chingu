import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/auth_provider.dart';

/// 活動詳情頁（參考 Timeleft 截圖 2 & 3）
class EventDetailScreen extends StatelessWidget {
  final DinnerEventModel event;
  final DinnerGroupModel? group;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部返回按鈕
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    color: AppColorsMinimal.textPrimary,
                  ),
                ],
              ),
            ),
            // 內容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // 狀態標籤
                    _buildStatusBadge(),
                    const SizedBox(height: 20),
                    // Dinner 資訊卡
                    _buildDinnerInfoCard(),
                    const SizedBox(height: 16),
                    // Restaurant 資訊卡
                    if (group?.restaurantName != null) ...[
                      _buildRestaurantCard(),
                      const SizedBox(height: 16),
                    ],
                    // Feedback 區塊
                    _buildFeedbackCard(context),
                    const SizedBox(height: 16),
                    // Group 區塊（永遠顯示）
                    _buildGroupCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 狀態標籤
  Widget _buildStatusBadge() {
    final isPast = event.eventDate.isBefore(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surfaceVariant,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
      ),
      child: Text(
        isPast ? '此活動已結束' : '活動進行中',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColorsMinimal.textSecondary,
        ),
      ),
    );
  }

  /// Dinner 資訊卡（參考 Timeleft 截圖 2）
  Widget _buildDinnerInfoCard() {
    final dateStr = DateFormat('EEEE, MMMM d', 'zh_TW').format(event.eventDate);
    final timeStr = DateFormat('HH:mm').format(event.eventDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖示 + 標題
          Row(
            children: [
              Icon(
                Icons.restaurant_rounded,
                size: 28,
                color: AppColorsMinimal.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Dinner',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 日期
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 15,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // 時間
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 15,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
          if (event.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            // 城市
            Text(
              event.city,
              style: TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'In Mandarin',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Restaurant 資訊卡（參考 Timeleft 截圖 2）
  Widget _buildRestaurantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 餐廳名稱
          Text(
            group!.restaurantName ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          if (group!.restaurantAddress != null) ...[
            const SizedBox(height: 6),
            Text(
              group!.restaurantAddress!,
              style: TextStyle(
                fontSize: 14,
                color: AppColorsMinimal.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 地圖佔位（靜態地圖或未來整合 Google Maps）
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColorsMinimal.surfaceVariant,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 40,
                  color: AppColorsMinimal.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  '📍 ${group!.restaurantName ?? "餐廳位置"}',
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
    );
  }

  /// Feedback 區塊（參考 Timeleft 截圖 2/3）
  Widget _buildFeedbackCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題 + 頭像
          Row(
            children: [
              Text(
                'Feedback',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
              const Spacer(),
              // 成員頭像疊加
              SizedBox(
                width: 100,
                height: 32,
                child: Stack(
                  children: List.generate(
                    (group?.participantIds.length ?? 3).clamp(0, 5),
                    (i) => Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColorsMinimal.primaryBackground,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppColorsMinimal.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '分享你的體驗來改善配對品質！',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final reviewProvider = context.read<ReviewProvider>();
                final userId = authProvider.uid;
                if (userId == null) return;

                await reviewProvider.loadPendingReviews(userId);
                if (!context.mounted) return;

                if (reviewProvider.pendingGroups.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.review,
                    arguments: {
                      'group': reviewProvider.pendingGroups.first,
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.textPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppColorsMinimal.radiusMD,
                  ),
                ),
                elevation: 0,
              ),
              child: const Text(
                '分享我的回饋',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Group 區塊（參考 Timeleft 截圖 3）
  Widget _buildGroupCard() {
    // 優先用群組資料，沒有則 fallback 到活動報名人數
    final participantCount = group?.participantIds.length 
        ?? event.signedUpUsers.length;
    final previews = group?.companionPreviews ?? [];
    final displayCount = participantCount > 0 ? participantCount : 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Participants
          Text(
            'Participants',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are in Chingu Table',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // 頭像列
          SizedBox(
            height: 40,
            child: Stack(
              children: List.generate(
                displayCount.clamp(0, 6),
                (i) => Positioned(
                  left: i * 24.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorsMinimal.primaryBackground,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: AppColorsMinimal.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New people are waiting for you!',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
            ),
          ),

          // Industries
          if (previews.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Industries',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColorsMinimal.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            ...previews.map((p) {
              final industry = p['industryCategory'] ?? 'Services';
              final emoji = _industryEmoji(industry);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$emoji $industry',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
              );
            }),

            // Nationalities
            if (previews.any((p) => p['nationality'] != null)) ...[
              const SizedBox(height: 20),
              Text(
                'Nationalities',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColorsMinimal.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              ...previews
                  .where((p) => p['nationality'] != null)
                  .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '🇹🇼 ${p['nationality']}',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  String _industryEmoji(String industry) {
    switch (industry.toLowerCase()) {
      case 'arts': return '🎨';
      case 'financial services': return '💹';
      case 'healthcare': return '🏥';
      case 'technology': return '💻';
      case 'education': return '📚';
      case 'food': case 'food & beverage': return '🍽️';
      default: return '👤';
    }
  }
}
