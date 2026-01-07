import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/event_filter_widget.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  String _selectedDistrict = '全部';

  // Mock data for events
  final List<Map<String, dynamic>> _allEvents = [
    {
      'title': '6人晚餐聚會',
      'date': '2025/10/15',
      'time': '19:00',
      'budget': 'NT\$ 500-800 / 人',
      'location': '台北市信義區',
      'isUpcoming': true,
    },
    {
      'title': '6人晚餐聚會',
      'date': '2025/10/18',
      'time': '18:30',
      'budget': 'NT\$ 800-1200 / 人',
      'location': '台北市大安區',
      'isUpcoming': true,
    },
    {
      'title': '6人晚餐聚會',
      'date': '2025/10/01',
      'time': '19:30',
      'budget': 'NT\$ 600-900 / 人',
      'location': '台北市中山區',
      'isUpcoming': false,
    },
  ];

  void _onFilterChanged(String district) {
    setState(() {
      _selectedDistrict = district;
    });
  }

  List<Map<String, dynamic>> _getFilteredEvents(bool isUpcoming) {
    return _allEvents.where((event) {
      final matchesType = event['isUpcoming'] == isUpcoming;
      final matchesDistrict = _selectedDistrict == '全部' ||
          (event['location'] as String).contains(_selectedDistrict);
      return matchesType && matchesDistrict;
    }).toList();
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
            EventFilterWidget(
              selectedDistrict: _selectedDistrict,
              onDistrictSelected: _onFilterChanged,
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: chinguTheme?.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, bool isUpcoming) {
    final events = _getFilteredEvents(isUpcoming);

    if (events.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '沒有符合條件的活動',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          title: event['title'],
          date: event['date'],
          time: event['time'],
          budget: event['budget'],
          location: event['location'],
          isUpcoming: event['isUpcoming'],
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.eventDetail);
          },
        );
      },
    );
  }
}
