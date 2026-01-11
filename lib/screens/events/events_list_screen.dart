import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/widgets/empty_state.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final chinguTheme = theme.extension<ChinguTheme>(); // Not needed if AnimatedTabBar handles it internally

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedTabBar(
              tabs: const ['📅 即將到來', '📋 歷史記錄'],
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildEventsList(context, true),
                _buildEventsList(context, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, bool isUpcoming) {
    final List<Widget> events = [
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
    ];

    if (events.isEmpty) {
      return EmptyStateWidget(
        icon: isUpcoming ? Icons.calendar_today_rounded : Icons.history_rounded,
        title: isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
        description: isUpcoming ? '去探索更多有趣的晚餐聚會吧！' : '您還沒有參加過任何活動',
        actionLabel: isUpcoming ? '瀏覽活動' : null,
        onActionPressed: isUpcoming
            ? () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.mainNavigation,
                  (route) => false,
                  arguments: {'initialIndex': 2}, // Explore tab
                );
              }
            : null,
        useGradientBackground: true,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: events,
    );
  }
}
