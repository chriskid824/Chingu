import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/screens/home/widgets/booking_bottom_sheet.dart';

/// 狀態 1：未報名 — 邀請卡 + 倒數截止 + CTA 報名按鈕
class InviteCard extends StatelessWidget {
  const InviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final chinguTheme = Theme.of(context).extension<ChinguTheme>();
    final deadline = _nextSignupDeadline();
    final remaining = deadline.difference(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: chinguTheme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // 圖標
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: chinguTheme?.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 標題
          Text(
            '這週四，和 5 位新朋友\n共進一場驚喜晚餐',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),

          // 特色標籤
          Text(
            '智能配對 · 性別平衡 · 匿名保護',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColorsMinimal.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 倒數截止提示
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.spaceLG,
              vertical: AppColorsMinimal.spaceSM,
            ),
            decoration: BoxDecoration(
              color: AppColorsMinimal.primaryBackground,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
            ),
            child: Text(
              _deadlineText(remaining),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColorsMinimal.primary,
              ),
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),

          // CTA 按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const BookingBottomSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                elevation: 0,
              ),
              child: const Text(
                '我要報名',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 計算下次報名截止時間（本週二中午 12:00，若已過則下週二）
  DateTime _nextSignupDeadline() {
    final now = DateTime.now();
    final daysUntilTuesday = (DateTime.tuesday - now.weekday + 7) % 7;
    final nextTuesday = DateTime(
      now.year, now.month, now.day + daysUntilTuesday, 12, 0,
    );
    if (now.isAfter(nextTuesday)) {
      return nextTuesday.add(const Duration(days: 7));
    }
    return nextTuesday;
  }

  String _deadlineText(Duration remaining) {
    if (remaining.isNegative) return '報名已截止';
    if (remaining.inHours < 1) return '報名即將截止！';
    if (remaining.inHours < 24) return '距報名截止還有 ${remaining.inHours} 小時';
    return '距報名截止還有 ${remaining.inDays} 天';
  }
}
