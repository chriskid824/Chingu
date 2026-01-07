import 'package:flutter/material.dart';
import 'package:chingu/screens/home/widgets/booking_bottom_sheet.dart';

import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/user_card.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/matching_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';

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
        
        // 載入配對候選人
        final currentUser = authProvider.userModel;
        if (currentUser != null) {
          context.read<MatchingProvider>().loadCandidates(currentUser);
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 自定義 AppBar 帶漸層
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, // 移除返回箭頭
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chingu',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: chinguTheme?.error ?? theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // 歡迎橫幅 - 使用透明漸層
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.transparentGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final name = authProvider.userModel?.name ?? 'User';
                                    return Text(
                                      '嗨，$name',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '今天想和誰共進晚餐？',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 快速操作
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.search_rounded,
                          '尋找配對',
                          theme.colorScheme.primary,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          Icons.calendar_today_rounded,
                          '我的預約',
                          theme.colorScheme.secondary,
                          () {},
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 即將到來的晚餐
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '即將到來的晚餐',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.eventsList);
                        },
                        child: const Text('查看全部'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 使用 Consumer 顯示真實活動
                Consumer<DinnerEventProvider>(builder: (context, eventProvider, _) {
                  if (eventProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (eventProvider.myEvents.isEmpty) {
                    return Padding(
                    padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '還沒有活動',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const BookingBottomSheet(),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('報名參加週四晚餐'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...eventProvider.myEvents.take(3).map((event) {
                        final dateTime = event.dateTime;
                        final dateStr = DateFormat('yyyy/MM/dd HH:mm', 'zh_TW').format(dateTime);
                        final budgetStr = _getBudgetRangeText(event.budgetRange);
                        final location = '${event.city}${event.district}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEventCard(
                            context,
                            '6人晚餐聚會',
                            dateStr,
                            budgetStr,
                            location,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.eventDetail,
                                arguments: {'eventId': event.id},
                              );
                            },
                          ),
                        );
                      }).toList(),

                      if (eventProvider.canBookMore)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const BookingBottomSheet(),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('報名其他場次'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                
                const SizedBox(height: 24),
                
                // 推薦配對
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.secondaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '推薦配對',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '✨',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                
                
                const SizedBox(height: 12),
                
                Consumer<MatchingProvider>(
                  builder: (context, matchingProvider, _) {
                    if (matchingProvider.isLoading) {
                      return const SizedBox(
                        height: 220,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final candidates = matchingProvider.candidates.take(5).toList();

                    if (candidates.isEmpty) {
                      return Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暫無推薦配對',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.matching);
                              },
                              child: const Text('前往配對頁面'),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: candidates.length + 1, // +1 for "查看更多" card
                        itemBuilder: (context, index) {
                          if (index == candidates.length) {
                            // "查看更多" card
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(left: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, AppRoutes.matching);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 48,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '查看更多',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final candidate = candidates[index];
                          return UserCard(
                            name: candidate.name,
                            age: candidate.age,
                            job: candidate.job ?? '未填寫職業',
                            jobIcon: Icons.work_outline_rounded,
                            color: theme.colorScheme.primary,
                            matchScore: 85 + (index * 2), // Simple scoring for now
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.matching);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventCard(BuildContext context, String title, String time, String budget, String location, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chinguTheme?.surfaceVariant ?? theme.dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: chinguTheme?.shadowLight ?? Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      budget,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String _getBudgetRangeText(int range) {
    switch (range) {
      case 0:
        return 'NT\$ 200-500 / 人';
      case 1:
        return 'NT\$ 500-800 / 人';
      case 2:
        return 'NT\$ 800-1200 / 人';
      case 3:
        return 'NT\$ 1200+ / 人';
      default:
        return '不限';
    }
  }
}
