import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Future<List<DinnerEventModel>> _eventsFuture;
  final DinnerEventService _eventService = DinnerEventService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadEvents();
  }

  void _loadEvents() {
    final userId = context.read<AuthProvider>().uid;
    if (userId != null) {
      _eventsFuture = _eventService.getUserEventHistory(userId);
    } else {
      _eventsFuture = Future.value([]);
    }
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
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加載失敗: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          final now = DateTime.now();
          final upcomingEvents = events.where((e) => e.dateTime.isAfter(now)).toList();
          final pastEvents = events.where((e) => e.dateTime.isBefore(now)).toList();

          upcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
                    _buildEventsList(context, upcomingEvents, true),
                    _buildEventsList(context, pastEvents, false),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today_rounded : Icons.history_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
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
          title: '${event.maxParticipants}人晚餐聚會',
          date: DateFormat('yyyy/MM/dd').format(event.dateTime),
          time: DateFormat('HH:mm').format(event.dateTime),
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            ).then((_) => setState(() => _loadEvents()));
          },
        );
      },
    );
  }
}
