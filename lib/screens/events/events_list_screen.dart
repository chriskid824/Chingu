import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/screens/events/event_history_screen.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _eventService = DinnerEventService();
  late Future<List<DinnerEventModel>> _upcomingEventsFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUpcomingEvents();
  }

  void _loadUpcomingEvents() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _upcomingEventsFuture = _eventService.getUserEvents(userId);
    } else {
      _upcomingEventsFuture = Future.value([]);
    }
  }

  Future<void> _refreshUpcoming() async {
    setState(() {
      _loadUpcomingEvents();
    });
    await _upcomingEventsFuture;
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
                _buildUpcomingList(context),
                const EventHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshUpcoming,
      child: FutureBuilder<List<DinnerEventModel>>(
        future: _upcomingEventsFuture,
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
               return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data ?? [];
            final upcoming = events.where((e) {
               return e.dateTime.isAfter(DateTime.now()) &&
                      e.status != EventStatus.cancelled &&
                      e.status != EventStatus.completed;
            }).toList();

            if (upcoming.isEmpty) {
               return ListView(
                 physics: const AlwaysScrollableScrollPhysics(),
                 children: const [
                   SizedBox(height: 100),
                   Center(child: Text('沒有即將到來的活動')),
                 ],
               );
            }

            return ListView.builder(
               padding: const EdgeInsets.all(16),
               itemCount: upcoming.length,
               itemBuilder: (context, index) {
                  final event = upcoming[index];
                  return EventCard(
                    title: '6人晚餐聚會',
                    date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                    time: DateFormat('HH:mm').format(event.dateTime),
                    budget: event.budgetRangeText,
                    location: '${event.city} ${event.district}',
                    isUpcoming: true,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.eventDetail,
                        arguments: event.id,
                      );
                    },
                  );
               }
            );
        }
      )
    );
  }
}
