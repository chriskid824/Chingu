import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _eventService = DinnerEventService();
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
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
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
          final upcomingEvents = events.where((e) =>
            e.status != EventStatus.completed &&
            e.status != EventStatus.cancelled
          ).toList();

          final pastEvents = events.where((e) =>
            e.status == EventStatus.completed ||
            e.status == EventStatus.cancelled
          ).toList();

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
                    _buildEventsList(context, upcomingEvents, true, userId),
                    _buildEventsList(context, pastEvents, false, userId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> events, bool isUpcoming, String userId) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isWaitlisted = event.waitlistIds.contains(userId);

          String statusText;
          Color? statusColor;

          if (isWaitlisted) {
            statusText = '候補中 (${event.waitlistIds.indexOf(userId) + 1})';
            statusColor = Theme.of(context).colorScheme.tertiary;
          } else {
            statusText = event.statusText;
            if (event.status == EventStatus.confirmed) {
               // Default success color is handled in EventCard if null
            } else if (event.status == EventStatus.cancelled) {
               statusColor = Theme.of(context).colorScheme.error;
            } else if (event.status == EventStatus.pending) {
               statusColor = Theme.of(context).colorScheme.secondary;
            }
          }

          return EventCard(
            title: '6人晚餐聚會',
            date: DateFormat('yyyy/MM/dd').format(event.dateTime),
            time: DateFormat('HH:mm').format(event.dateTime),
            budget: event.budgetRangeText + ' / 人',
            location: '${event.city}${event.district}',
            isUpcoming: isUpcoming,
            statusText: statusText,
            statusColor: statusColor,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: event.id,
              );
            },
          );
        },
      ),
    );
  }
}
