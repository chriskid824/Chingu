import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/screens/home/home_state.dart';
import 'package:chingu/screens/home/widgets/invite_card.dart';
import 'package:chingu/screens/home/widgets/matching_card.dart';
import 'package:chingu/screens/home/widgets/companion_preview_card.dart';
import 'package:chingu/screens/home/widgets/restaurant_reveal_card.dart';
import 'package:chingu/screens/home/widgets/pending_review_card.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
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
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
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
                  _buildGreetingSection(),

                  const SizedBox(height: AppColorsMinimal.spaceXL),

                  // ─── Zone 2: 主活動卡片（5 狀態切換）───
                  _buildSectionTitle('本週晚餐'),
                  const SizedBox(height: AppColorsMinimal.spaceMD),
                  _buildMainActivityCard(),

                  const SizedBox(height: AppColorsMinimal.space2XL),

                  // ─── Zone 2.5: 我的群組 ───
                  _buildMyGroupsSection(),

                  const SizedBox(height: AppColorsMinimal.space2XL),

                  // ─── Zone 3: 個人統計快捷卡 ───
                  _buildSectionTitle('你的旅程'),
                  const SizedBox(height: AppColorsMinimal.spaceMD),
                  _buildStatsRow(),

                  const SizedBox(height: AppColorsMinimal.space3XL),
                ],
              ),
            ),
          ),
        ],
      ),
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
        return RestaurantRevealCard(
          key: const ValueKey('fullReveal'),
          group: result.group!,
        );

      case HomeState.pendingReview:
        return PendingReviewCard(
          key: const ValueKey('pendingReview'),
          group: result.group!,
          currentUserId: userId,
        );
    }
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
                value: '$completedEvents',
                label: '已參加場次',
                color: AppColorsMinimal.primary,
              ),
            ),
            const SizedBox(width: AppColorsMinimal.spaceMD),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                value: '${friendIds.length}',
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
}
