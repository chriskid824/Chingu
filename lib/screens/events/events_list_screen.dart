import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/skeleton_loader.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '我的預約',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                indicator: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📅 即將到來'),
                  Tab(text: '📋 歷史記錄'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEventsList(context, true),
                  _buildEventsList(context, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsList(BuildContext context, bool isUpcoming) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // Show 4 skeleton items
        itemBuilder: (context, index) {
          return const SkeletonEventCard();
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EventCard(
          title: '6人晚餐聚會',
          date: '2025/10/15',
          time: '19:00',
          budget: 'NT\$ 500-800 / 人',
          location: '台北市信義區',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.eventDetail);
          },
        ),
        EventCard(
          title: '6人晚餐聚會',
          date: '2025/10/18',
          time: '18:30',
          budget: 'NT\$ 800-1200 / 人',
          location: '台北市大安區',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.eventDetail);
          },
        ),
        if (!isUpcoming)
          EventCard(
            title: '6人晚餐聚會',
            date: '2025/10/01',
            time: '19:30',
            budget: 'NT\$ 600-900 / 人',
            location: '台北市中山區',
            isUpcoming: isUpcoming,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.eventDetail);
            },
          ),
      ],
    );
  }
}
