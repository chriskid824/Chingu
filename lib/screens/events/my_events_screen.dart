import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _eventService = DinnerEventService();
  final AuthService _authService = AuthService();
  late Future<List<DinnerEventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _refreshEvents();
  }

  void _refreshEvents() {
    final user = _authService.currentUser;
    if (user != null) {
      _eventsFuture = _eventService.getUserEvents(user.uid);
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
              '我的活動',
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
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final allEvents = snapshot.data ?? [];
          final user = _authService.currentUser;
          final userId = user?.uid ?? '';

          // Filter events
          final upcomingEvents = <DinnerEventModel>[];
          final waitlistEvents = <DinnerEventModel>[];
          final historyEvents = <DinnerEventModel>[];

          final now = DateTime.now();

          for (var event in allEvents) {
            if (event.participantIds.contains(userId)) {
              if (event.status != 'cancelled' && event.dateTime.isAfter(now)) {
                upcomingEvents.add(event);
              } else {
                historyEvents.add(event);
              }
            } else if (event.waitlist.contains(userId)) {
               // Only show active waitlist for future events
               if (event.dateTime.isAfter(now)) {
                 waitlistEvents.add(event);
               } else {
                 historyEvents.add(event); // Expired waitlist to history? Or ignore.
                 // Let's add to history if status is not cancelled, but time passed.
               }
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedTabBar(
                  tabs: const ['已報名', '候補中', '歷史記錄'],
                  selectedIndex: _selectedIndex,
                  onTabSelected: _onTabSelected,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventsList(context, upcomingEvents, 'registered'),
                    _buildEventsList(context, waitlistEvents, 'waitlist'),
                    _buildEventsList(context, historyEvents, 'history'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> events, String type) {
    if (events.isEmpty) {
      return const Center(child: Text('沒有活動記錄'));
    }

    final chinguTheme = Theme.of(context).extension<ChinguTheme>();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _refreshEvents();
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          String? statusText;
          Color? statusColor;
          bool isUpcoming = true;

          if (type == 'waitlist') {
            statusText = '候補中 (${event.waitlist.indexOf(_authService.currentUser!.uid) + 1})';
            statusColor = chinguTheme?.warning ?? Colors.orange;
          } else if (type == 'history') {
            isUpcoming = false;
            if (event.status == 'cancelled') {
              statusText = '已取消';
              statusColor = Colors.grey;
            }
          }

          return EventCard(
            title: '6人晚餐聚會', // Or generate based on city/district
            date: "${event.dateTime.year}/${event.dateTime.month}/${event.dateTime.day}",
            time: "${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}",
            budget: event.budgetRangeText,
            location: "${event.city} ${event.district}",
            isUpcoming: isUpcoming,
            statusText: statusText,
            statusColor: statusColor,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: event.id,
              ).then((_) => setState(() => _refreshEvents()));
            },
          );
        },
      ),
    );
  }
}
