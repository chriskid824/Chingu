import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/screens/home/home_state.dart';
import 'package:chingu/screens/home/widgets/invite_card.dart';
import 'package:chingu/screens/home/widgets/matching_card.dart';
import 'package:chingu/screens/home/widgets/companion_preview_card.dart';
import 'package:chingu/screens/home/widgets/restaurant_reveal_card.dart';
// PendingReviewCard 移至 Events Tab，首頁只顯示晚餐狀態
import 'package:chingu/screens/home/widgets/booking_bottom_sheet.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
import 'package:chingu/widgets/appear_animation.dart';
import 'package:chingu/widgets/animated_counter.dart';
import 'package:chingu/widgets/bounce_button.dart';
import 'package:chingu/widgets/flip_card.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/dinner_group_provider.dart';
import 'package:chingu/providers/subscription_provider.dart';
import 'package:chingu/models/dinner_group_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 餐廳揭曉卡翻轉狀態（fullReveal 首次進入自動翻轉一次）
  bool _revealFlipped = false;
  bool _revealFlipScheduled = false;

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
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: CustomScrollView(
        slivers: [
          // ─── 頂部 AppBar ───
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
                      BounceButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        child: Container(
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
                  AppearAnimation(
                    child: _buildGreetingSection(),
                  ),

                  const SizedBox(height: AppColorsMinimal.spaceXL),

                  // ─── Zone 2: 主活動卡片（5 狀態切換）───
                  AppearAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('本週晚餐'),
                        const SizedBox(height: AppColorsMinimal.spaceMD),
                        _buildMainActivityCard(),
                      ],
                    ),
                  ),

                  // ─── 快捷報名入口（非未報名狀態時顯示）───
                  _buildQuickBookingEntry(),

                  const SizedBox(height: AppColorsMinimal.space2XL),

                  // ─── Zone 2.5: 我的群組 ───
                  AppearAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: _buildMyGroupsSection(),
                  ),

                  const SizedBox(height: AppColorsMinimal.space2XL),

                  // ─── Zone 3: 個人統計快捷卡 ───
                  AppearAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('你的旅程'),
                        const SizedBox(height: AppColorsMinimal.spaceMD),
                        _buildStatsRow(),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppColorsMinimal.space3XL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 快捷報名入口 ============

  Widget _buildQuickBookingEntry() {
    return Consumer2<DinnerEventProvider, DinnerGroupProvider>(
      builder: (context, eventProvider, groupProvider, _) {
        final userId = context.read<AuthProvider>().uid ?? '';
        final result = HomeStateResolver.resolve(
          myEvents: eventProvider.myEvents,
          myGroups: groupProvider.myGroups,
          userId: userId,
        );

        // InviteCard 已有報名按鈕，這兩個狀態不需要額外入口
        if (result.state == HomeState.notSignedUp ||
            result.state == HomeState.pendingReview) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppColorsMinimal.spaceMD),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const BookingBottomSheet(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColorsMinimal.spaceLG,
                vertical: AppColorsMinimal.spaceMD,
              ),
              decoration: BoxDecoration(
                color: AppColorsMinimal.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                border: Border.all(
                  color: AppColorsMinimal.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColorsMinimal.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppColorsMinimal.spaceSM),
                  Text(
                    '報名下一場晚餐',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColorsMinimal.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColorsMinimal.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============ Zone 1: 問候 ============

  Widget _buildGreetingSection() {
    return Consumer2<AuthProvider, DinnerEventProvider>(
      builder: (context, authProvider, eventProvider, child) {
        final name = authProvider.userModel?.name ?? 'User';
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? '早安' : (hour < 18 ? '午安' : '晚安');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting，$name',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceXS),
            Text(
              '期待和新朋友共進晚餐嗎？',
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

  // ============ Zone 2: 主活動卡片 — 5 狀態 ============

  Widget _buildMainActivityCard() {
    return Consumer2<DinnerEventProvider, DinnerGroupProvider>(
      builder: (context, eventProvider, groupProvider, _) {
        if (eventProvider.isLoading || groupProvider.isLoading) {
          return const HomeCardSkeleton();
        }

        final userId = context.read<AuthProvider>().uid ?? '';
        final result = HomeStateResolver.resolve(
          myEvents: eventProvider.myEvents,
          myGroups: groupProvider.myGroups,
          userId: userId,
        );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCardForState(result, userId),
        );
      },
    );
  }

  Widget _buildCardForState(HomeStateResult result, String userId) {
    switch (result.state) {
      case HomeState.notSignedUp:
        return const InviteCard(key: ValueKey('invite'));

      case HomeState.matching:
        return MatchingCard(
          key: const ValueKey('matching'),
          event: result.event,
        );

      case HomeState.partialReveal:
        return CompanionPreviewCard(
          key: const ValueKey('partialReveal'),
          group: result.group!,
          currentUserId: userId,
        );

      case HomeState.fullReveal:
        return _buildRevealFlipCard(result.group!);

      case HomeState.pendingReview:
        // 評價功能移至 Events Tab，首頁回到未報名狀態
        return const InviteCard(key: ValueKey('invite_after_review'));
    }
  }

  // ============ fullReveal: 神秘封面 → 翻牌揭曉 ============

  Widget _buildRevealFlipCard(DinnerGroupModel group) {
    // 首次進入 fullReveal 狀態，進場後 600ms 自動翻轉
    if (!_revealFlipScheduled) {
      _revealFlipScheduled = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !_revealFlipped) {
          setState(() => _revealFlipped = true);
        }
      });
    }

    return FlipCard(
      key: const ValueKey('fullReveal'),
      isFlipped: _revealFlipped,
      // 只允許封面→餐廳卡的單向翻轉:翻開後點到按鈕邊緣不可把卡翻回去
      onFlip: () {
        if (!_revealFlipped) {
          setState(() => _revealFlipped = true);
        }
      },
      front: _buildRevealFrontCover(),
      back: RestaurantRevealCard(group: group),
    );
  }

  /// 神秘封面 — 翻牌前的正面
  Widget _buildRevealFrontCover() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppColorsMinimal.spaceXL,
        vertical: AppColorsMinimal.space3XL,
      ),
      decoration: BoxDecoration(
        gradient: AppColorsMinimal.primaryGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
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
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXL),
          const Text(
            '今晚的餐廳',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceSM),
          Text(
            '即將揭曉，敬請期待',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Zone 2.5: 我的群組 ============

  Widget _buildMyGroupsSection() {
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

    return BounceButton(
      onPressed: () {
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
          'title': '等待同伴揭曉',
          'color': AppColorsMinimal.warning,
        };
      case 'info_revealed':
        return {
          'icon': Icons.people_rounded,
          'title': '同伴已揭曉',
          'color': AppColorsMinimal.primary,
        };
      case 'location_revealed':
        return {
          'icon': Icons.restaurant_rounded,
          'title': '餐廳已揭曉',
          'color': AppColorsMinimal.success,
        };
      default:
        return {
          'icon': Icons.check_circle_rounded,
          'title': '晚餐結束',
          'color': AppColorsMinimal.success,
        };
    }
  }

  // ============ Zone 3: 個人統計 ============

  Widget _buildStatsRow() {
    return Consumer2<DinnerEventProvider, DinnerGroupProvider>(
      builder: (context, eventProvider, groupProvider, _) {
        final completedEvents = eventProvider.myEvents
            .where((e) => e.eventDate.isBefore(DateTime.now()))
            .length;

        final friendIds = <String>{};
        final authUid = context.read<AuthProvider>().uid;
        for (final group in groupProvider.myGroups) {
          if (group.status == 'completed' || group.status == 'location_revealed') {
            friendIds.addAll(
              group.participantIds.where((id) => id != authUid),
            );
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.dinner_dining_rounded,
                value: completedEvents,
                label: '已參加場次',
                color: AppColorsMinimal.primary,
              ),
            ),
            const SizedBox(width: AppColorsMinimal.spaceMD),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                value: friendIds.length,
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
    required int value,
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
          AnimatedCounter(
            value: value,
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
}
