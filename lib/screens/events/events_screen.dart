import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_animations.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/widgets/appear_animation.dart';
import 'package:chingu/widgets/bounce_button.dart';
import 'package:chingu/widgets/skeleton_loading.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/dinner_group_provider.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_event_model.dart';

/// Events Tab — 歷史活動列表（參考 Timeleft Events 頁面設計）
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;
    if (userId == null) return;

    final eventProvider = context.read<DinnerEventProvider>();
    final groupProvider = context.read<DinnerGroupProvider>();
    final reviewProvider = context.read<ReviewProvider>();

    await Future.wait([
      eventProvider.fetchMyEvents(userId),
      groupProvider.fetchMyGroups(userId),
      reviewProvider.loadPendingReviews(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // 頁面標題
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColorsMinimal.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // 回饋 Banner
              SliverToBoxAdapter(child: _buildFeedbackBanner()),

              // 即將到來
              _buildUpcomingSection(),

              // Past 分區標題
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    '過去的晚餐',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColorsMinimal.textSecondary,
                    ),
                  ),
                ),
              ),

              // 歷史活動列表
              _buildEventsList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 即將到來的晚餐
  Widget _buildUpcomingSection() {
    return Consumer<DinnerEventProvider>(
      builder: (context, eventProvider, _) {
        final now = DateTime.now().toUtc();
        final upcomingEvents = eventProvider.myEvents
            .where((e) => e.eventDate.toUtc().isAfter(now))
            .toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        if (upcomingEvents.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Text(
                  '即將到來',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColorsMinimal.primary,
                  ),
                ),
              ),
              ...upcomingEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final dayOfWeek = DateFormat('EEEE', 'zh_TW').format(event.eventDate);
                final dateStr = DateFormat('MM/dd').format(event.eventDate);
                final daysLeft = event.eventDate.difference(DateTime.now()).inDays;
                final daysText = daysLeft == 0 ? '今天' : '$daysLeft 天後';

                return AppearAnimation(
                  delay: AppAnimations.staggerInterval * index.clamp(0, 6),
                  child: BounceButton(
                    onPressed: () => _navigateToDetail(event),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorsMinimal.primary.withValues(alpha: 0.08),
                            AppColorsMinimal.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
                        border: Border.all(
                          color: AppColorsMinimal.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColorsMinimal.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: AppColorsMinimal.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppColorsMinimal.spaceLG),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$dayOfWeek · $dateStr',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColorsMinimal.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.city,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColorsMinimal.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColorsMinimal.primary,
                              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
                            ),
                            child: Text(
                              daysText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppColorsMinimal.spaceSM),
            ],
          ),
        );
      },
    );
  }

  /// 回饋提醒 Banner（參考 Timeleft 截圖 1）
  Widget _buildFeedbackBanner() {
    if (_bannerDismissed) return const SizedBox.shrink();

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        if (!reviewProvider.hasPendingReviews) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColorsMinimal.surface,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppColorsMinimal.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 頭像列 + 關閉按鈕
              Row(
                children: [
                  const Spacer(),
                  // 成員頭像疊加（動態數量）
                  Builder(builder: (context) {
                    final count = (reviewProvider.pendingGroups.isNotEmpty
                        ? (reviewProvider.pendingGroups.first['memberIds'] as List?)?.length ?? 5
                        : 5).clamp(2, 7);
                    return SizedBox(
                      width: count * 22.0 + 14,
                      height: 36,
                      child: Stack(
                        children: List.generate(count, (i) => Positioned(
                          left: i * 22.0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColorsMinimal.primaryBackground,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: AppColorsMinimal.textTertiary,
                            ),
                          ),
                        )),
                      ),
                    );
                  }),
                  const Spacer(),
                  // 關閉按鈕
                  GestureDetector(
                    onTap: () => setState(() => _bannerDismissed = true),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColorsMinimal.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 引導語
              Text(
                '覺得這次體驗如何？',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '分享回饋，配對更準確！',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColorsMinimal.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // CTA 按鈕
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('目前沒有待評價的群組'),
                          duration: Duration(seconds: 2),
                        ),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 歷史活動列表
  Widget _buildEventsList() {
    return Consumer<DinnerEventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading) {
          return const SliverToBoxAdapter(child: EventsListSkeleton());
        }

        final now = DateTime.now().toUtc();
        final pastEvents = eventProvider.myEvents
            .where((e) => e.eventDate.toUtc().isBefore(now))
            .toList()
          ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

        if (pastEvents.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppColorsMinimal.space2XL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsMinimal.shadowLight,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 44,
                        color: AppColorsMinimal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppColorsMinimal.spaceXL),
                    Text(
                      '還沒有晚餐回憶',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppColorsMinimal.spaceSM),
                    Text(
                      '報名你的第一場晚餐\n每一次相遇都是新的故事',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColorsMinimal.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = pastEvents[index];
                return AppearAnimation(
                  delay: AppAnimations.staggerInterval * index.clamp(0, 6),
                  child: _buildEventCard(event),
                );
              },
              childCount: pastEvents.length,
            ),
          ),
        );
      },
    );
  }

  /// 單張活動卡片（參考 Timeleft 截圖 1 的卡片設計）
  Widget _buildEventCard(DinnerEventModel event) {
    final dayOfWeek = DateFormat('EEEE', 'zh_TW').format(event.eventDate);
    final dateStr = DateFormat('MM/dd').format(event.eventDate);
    final timeStr = DateFormat('HH:mm').format(event.eventDate);
    final city = event.city.isNotEmpty ? event.city : '';
    final displayTitle = city.isNotEmpty
        ? '$dayOfWeek · $city'
        : dayOfWeek;

    return BounceButton(
      onPressed: () => _navigateToDetail(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            // 刀叉圖示
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColorsMinimal.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: AppColorsMinimal.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // 日期資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · $timeStr',
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
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(DinnerEventModel event) {
    // 嘗試找到對應群組
    final groupProvider = context.read<DinnerGroupProvider>();
    final matchingGroups = groupProvider.myGroups
        .where((g) => g.eventId == event.id)
        .toList();

    Navigator.pushNamed(
      context,
      AppRoutes.eventDetail,
      arguments: {
        'event': event,
        'group': matchingGroups.isNotEmpty ? matchingGroups.first : null,
      },
    );
  }
}
