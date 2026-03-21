import 'package:flutter/material.dart';
import 'package:chingu/screens/home/widgets/booking_bottom_sheet.dart';
import 'package:chingu/screens/home/widgets/countdown_ring.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/dinner_group_provider.dart';
import 'package:chingu/providers/subscription_provider.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';
import 'package:chingu/widgets/skeleton_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.uid != null) {
        context.read<DinnerEventProvider>().fetchMyEvents(authProvider.uid!);
        context.read<DinnerGroupProvider>().fetchMyGroups(authProvider.uid!);
        context.read<SubscriptionProvider>().loadSubscription(authProvider.uid!);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: CustomScrollView(
        slivers: [
          // ─── 頂部 AppBar（極簡白底 + 暖橘標題）───
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColorsMinimal.background,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColorsMinimal.spaceXL, AppColorsMinimal.spaceLG,
                    AppColorsMinimal.spaceXL, 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chingu',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColorsMinimal.primary,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColorsMinimal.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColorsMinimal.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColorsMinimal.spaceXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppColorsMinimal.spaceSM),
                  
                  // ─── Zone 1: 問候區 ───
                  _buildGreetingSection(theme),
                  
                  const SizedBox(height: AppColorsMinimal.spaceXL),
                  
                  // ─── Zone 2: 主活動卡片（4 狀態切換）───
                  _buildSectionTitle('本週晚餐'),
                  const SizedBox(height: AppColorsMinimal.spaceMD),
                  _buildMainActivityCard(theme, chinguTheme),
                  
                  const SizedBox(height: AppColorsMinimal.space2XL),
                  
                  // ─── Zone 2.5: 我的群組 ───
                  _buildMyGroupsSection(theme),
                  
                  const SizedBox(height: AppColorsMinimal.space2XL),
                  
                  // ─── Zone 3: 個人統計快捷卡 ───
                  _buildSectionTitle('你的旅程'),
                  const SizedBox(height: AppColorsMinimal.spaceMD),
                  _buildStatsRow(theme),
                  
                  const SizedBox(height: AppColorsMinimal.space3XL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(ThemeData theme) {
    return Consumer2<AuthProvider, DinnerEventProvider>(
      builder: (context, authProvider, eventProvider, child) {
        final name = authProvider.userModel?.name ?? 'User';
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? '早安' : (hour < 18 ? '午安' : '晚安');
        
        // 動態副標題
        final subtitle = _getGreetingSubtitle(eventProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting，$name 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceXS),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getGreetingSubtitle(DinnerEventProvider eventProvider) {
    if (eventProvider.isLoading) {
      return '期待和新朋友共進晚餐嗎？';
    }

    final myEvents = eventProvider.myEvents;
    if (myEvents.isEmpty) {
      // 未報名
      final now = DateTime.now();
      final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
      if (daysUntilFriday == 0) return '今天是報名截止日，快來報名！';
      return '本週還有 $daysUntilFriday 天可以報名！';
    }

    // 找最近的活動
    final nextEvent = myEvents.firstWhere(
      (e) => e.eventDate.isAfter(DateTime.now()),
      orElse: () => myEvents.last,
    );

    final now = DateTime.now();
    final diff = nextEvent.eventDate.difference(now);

    if (diff.isNegative) {
      // 活動已過 → 可能待評價
      return '記得給同桌朋友評價哦 ⭐';
    } else if (diff.inHours < 12) {
      // 活動當天
      return '今晚就是晚餐日！準備好了嗎？ 🎉';
    } else {
      // 已報名，倒數中
      return '距離晚餐還有 ${diff.inDays} 天 🎉';
    }
  }

  // ============ Zone 2: 主活動卡片 ============
  
  Widget _buildMainActivityCard(ThemeData theme, ChinguTheme? chinguTheme) {
    return Consumer<DinnerEventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading) {
          return _buildLoadingCard();
        }

        if (eventProvider.myEvents.isEmpty) {
          // 狀態 1: 未報名 — 顯示邀請卡
          return _buildInviteCard(theme, chinguTheme);
        }

        // 取最近一場活動
        final event = eventProvider.myEvents.first;
        final now = DateTime.now();
        final diff = event.eventDate.difference(now);

        if (diff.isNegative) {
          // 活動已結束 — 檢查是否在 48 小時評價窗口內
          final hoursSinceEnd = diff.inHours.abs();
          if (hoursSinceEnd <= 48) {
            // 狀態 5: 評價模式（晚餐結束後 48 小時內）
            return _buildReviewCard(theme, chinguTheme, event);
          }
          // 狀態 4: 活動已完全結束
          return _buildCompletedCard(theme, event);
        } else if (diff.inHours < 3) {
          // 狀態 3: 即將開始 / 餐廳已解鎖
          return _buildRevealedCard(theme, chinguTheme, event);
        } else {
          // 狀態 2: 已報名 / 倒數中
          return _buildCountdownCard(theme, chinguTheme, event);
        }
      },
    );
  }

  /// 狀態 1: 邀請卡 — 大按鈕 CTA
  Widget _buildInviteCard(ThemeData theme, ChinguTheme? chinguTheme) {
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
          Text(
            '🧠 智能配對 · 👫 性別平衡 · 🔒 匿名保護',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColorsMinimal.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXL),
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
                '我要報名 🍽️',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 狀態 2: 倒數卡 — 圓環 + 漸進資訊
  Widget _buildCountdownCard(ThemeData theme, ChinguTheme? chinguTheme, dynamic event) {
    final dateStr = DateFormat('MM/dd (E)', 'zh_TW').format(event.eventDate);
    final timeStr = DateFormat('HH:mm').format(event.eventDate);

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
        border: Border.all(color: AppColorsMinimal.surfaceVariant.withValues(alpha: 0.6)),
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
          CountdownRing(
            targetDate: event.eventDate,
            size: 160,
            strokeWidth: 8,
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
          // 活動資訊列
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.calendar_today_rounded, dateStr),
              const SizedBox(width: AppColorsMinimal.spaceMD),
              _buildInfoChip(Icons.access_time_rounded, timeStr),
              const SizedBox(width: AppColorsMinimal.spaceMD),
              _buildInfoChip(Icons.check_circle_rounded, '已報名 ✓'),
            ],
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
          // 地點保密提示
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
                  '🔮 驚喜地點倒數揭曉中',
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

  /// 狀態 3: 解鎖卡 — 餐廳資訊已揭曉
  Widget _buildRevealedCard(ThemeData theme, ChinguTheme? chinguTheme, dynamic event) {
    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: chinguTheme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.primary.withValues(alpha: 0.3),
        ),
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
            child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),
          Text(
            '🎉 餐廳已揭曉！',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '晚上 7 點見！',
            style: TextStyle(
              fontSize: 15,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
          // 破冰話題提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
            decoration: BoxDecoration(
              color: AppColorsMinimal.surface,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💬 今晚的破冰話題',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '「如果可以和世界上任何人共進晚餐，你會選誰？」',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColorsMinimal.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 狀態 5: 評價卡 — 晚餐結束後 48 小時內
  Widget _buildReviewCard(ThemeData theme, ChinguTheme? chinguTheme, dynamic event) {
    final dateStr = DateFormat('MM/dd (E)', 'zh_TW').format(event.eventDate);
    final signedUp = event.signedUpUsers?.length ?? 6;
    final toReview = signedUp - 1; // 不含自己

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: chinguTheme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 圖示
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: chinguTheme?.secondaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
          Text(
            '$dateStr 的晚餐已結束',
            style: TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '你覺得今晚的夥伴如何？',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '對 $toReview 位同桌者做「想再見面」評價\n雙方都想的話，就能開始聊天 💬',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXL),
          
          // 同桌者頭像列
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              toReview > 5 ? 5 : toReview,
              (index) => Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColorsMinimal.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColorsMinimal.secondary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColorsMinimal.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppColorsMinimal.spaceXL),
          
          // 評價進度
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.spaceLG,
              vertical: AppColorsMinimal.spaceSM,
            ),
            decoration: BoxDecoration(
              color: AppColorsMinimal.surface,
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_rounded,
                  size: 16,
                  color: AppColorsMinimal.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '0 / $toReview 已完成',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColorsMinimal.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
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

                // 載入待評價群組
                await reviewProvider.loadPendingReviews(userId);

                if (!context.mounted) return;

                if (reviewProvider.pendingGroups.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.review,
                    arguments: {'group': reviewProvider.pendingGroups.first},
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
                '開始評價 ✨',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: AppColorsMinimal.spaceSM),
          
          // 超時提示
          Text(
            '⏰ 48 小時內完成評價，逾期將自動關閉',
            style: TextStyle(
              fontSize: 11,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 狀態 4: 已完成卡
  Widget _buildCompletedCard(ThemeData theme, dynamic event) {
    final dateStr = DateFormat('MM/dd (E)', 'zh_TW').format(event.eventDate);

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 48,
            color: AppColorsMinimal.success,
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),
          Text(
            '$dateStr 的晚餐已結束',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '期待你的評價和下次參與！',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceLG),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const BookingBottomSheet(),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsMinimal.primary,
                side: const BorderSide(color: AppColorsMinimal.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
              ),
              child: const Text('報名下一場 🍽️'),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Zone 2.5: 我的群組 ============

  Widget _buildMyGroupsSection(ThemeData theme) {
    return Consumer<DinnerGroupProvider>(
      builder: (context, groupProvider, _) {
        if (groupProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final groups = groupProvider.myGroups
            .where((g) => g.status != 'completed')
            .toList();

        if (groups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('我的群組'),
            const SizedBox(height: AppColorsMinimal.spaceMD),
            ...groups.map((group) => _buildGroupCard(group)),
          ],
        );
      },
    );
  }

  Widget _buildGroupCard(DinnerGroupModel group) {
    final statusConfig = _groupStatusConfig(group.status);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.groupDetail,
          arguments: {'group': group},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
        padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
        decoration: BoxDecoration(
          color: AppColorsMinimal.surface,
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          border: Border.all(color: AppColorsMinimal.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: AppColorsMinimal.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 狀態圖標
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (statusConfig['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
              ),
              child: Icon(
                statusConfig['icon'] as IconData,
                color: statusConfig['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: AppColorsMinimal.spaceLG),
            // 資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusConfig['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.participantIds.length} 人同桌',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColorsMinimal.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 箭頭
            Icon(
              Icons.chevron_right_rounded,
              color: AppColorsMinimal.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _groupStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'icon': Icons.hourglass_top_rounded,
          'title': '⏳ 等待同伴揭曉',
          'color': AppColorsMinimal.warning,
        };
      case 'info_revealed':
        return {
          'icon': Icons.people_rounded,
          'title': '👀 同伴已揭曉',
          'color': AppColorsMinimal.primary,
        };
      case 'location_revealed':
        return {
          'icon': Icons.restaurant_rounded,
          'title': '🎉 餐廳已揭曉',
          'color': AppColorsMinimal.success,
        };
      default:
        return {
          'icon': Icons.check_circle_rounded,
          'title': '✅ 晚餐結束',
          'color': AppColorsMinimal.success,
        };
    }
  }

  // ============ Zone 3: 個人統計 ============
  
  Widget _buildStatsRow(ThemeData theme) {
    return Consumer2<DinnerEventProvider, DinnerGroupProvider>(
      builder: (context, eventProvider, groupProvider, _) {
        // 已完成的活動數量
        final completedEvents = eventProvider.myEvents
            .where((e) => e.eventDate.isBefore(DateTime.now()))
            .length;
        // 認識的不重複朋友數（從已完成群組中統計）
        final friendIds = <String>{};
        final authUid = context.read<AuthProvider>().uid;
        for (final group in groupProvider.myGroups) {
          if (group.status == 'completed' || group.status == 'location_revealed') {
            friendIds.addAll(
              group.participantIds.where((id) => id != authUid),
            );
          }
        }
        final friendCount = friendIds.length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.dinner_dining_rounded,
                value: '$completedEvents',
                label: '已參加場次',
                color: AppColorsMinimal.primary,
              ),
            ),
            const SizedBox(width: AppColorsMinimal.spaceMD),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                value: '$friendCount',
                label: '認識的朋友',
                color: AppColorsMinimal.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXS),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ============ 共用元件 ============

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColorsMinimal.primary, AppColorsMinimal.secondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppColorsMinimal.spaceSM),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
      ],
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
          Icon(icon, size: 14, color: AppColorsMinimal.textSecondary),
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

  Widget _buildLoadingCard() {
    return const HomeCardSkeleton();
  }
}
