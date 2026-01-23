import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _eventService = DinnerEventService();

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
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

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
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventService.getUserEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          // Filter in memory for now
          final now = DateTime.now();
          final upcoming = events.where((e) => e.dateTime.isAfter(now)).toList();
          final past = events.where((e) => e.dateTime.isBefore(now)).toList();

          return Column(
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
                    _buildEventsList(context, upcoming, true),
                    _buildEventsList(context, past, false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> events, bool isUpcoming) {
    if (events.isEmpty) {
      return Center(
        child: Text(isUpcoming ? '沒有即將到來的活動' : '沒有歷史記錄'),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          title: '${event.maxParticipants}人晚餐聚會',
          date: dateFormat.format(event.dateTime),
          time: timeFormat.format(event.dateTime),
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(
                  eventId: event.id,
                  event: event
                ),
              ),
            );
          },
        );
      },
    );
  }
}
