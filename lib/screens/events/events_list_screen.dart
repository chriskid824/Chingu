import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
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
    final userId = authProvider.uid;

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
      body: userId == null
          ? const Center(child: Text('請先登入'))
          : FutureBuilder<List<DinnerEventModel>>(
              future: _eventService.getUserEvents(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('發生錯誤: ${snapshot.error}'));
                }

                final allEvents = snapshot.data ?? [];

                // Categorize events
                final upcomingEvents = <DinnerEventModel>[];
                final waitlistEvents = <DinnerEventModel>[];
                final historyEvents = <DinnerEventModel>[];
                final now = DateTime.now();

                for (var event in allEvents) {
                  final status = event.getUserRegistrationStatus(userId);

                  if (status == EventRegistrationStatus.waitlisted) {
                    waitlistEvents.add(event);
                  } else if (status == EventRegistrationStatus.registered) {
                    final isCompleted = event.status == EventStatus.completed ||
                                       event.status == EventStatus.cancelled ||
                                       event.dateTime.isBefore(now);

                    if (isCompleted) {
                      historyEvents.add(event);
                    } else {
                      upcomingEvents.add(event);
                    }
                  }
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedTabBar(
                        tabs: const ['📅 即將到來', '⏳ 候補名單', '📋 歷史記錄'],
                        selectedIndex: _selectedIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          _buildEventsList(context, upcomingEvents, 'upcoming'),
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
              _getEmptyMessage(type),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).disabledColor,
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
          title: '${event.participantIds.length}人晚餐聚會',
          date: DateFormat('yyyy/MM/dd').format(event.dateTime),
          time: DateFormat('HH:mm').format(event.dateTime),
          budget: event.budgetRangeText,
          location: '${event.city} ${event.district}',
          isUpcoming: type == 'upcoming',
          statusText: _getStatusText(event, type),
          statusColor: _getStatusColor(context, event, type),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event.id,
            );
          },
        );
      },
    );
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'upcoming':
        return '沒有即將到來的活動';
      case 'waitlist':
        return '沒有候補中的活動';
      case 'history':
        return '沒有歷史活動記錄';
      default:
        return '沒有活動';
    }
  }

  String _getStatusText(DinnerEventModel event, String type) {
    if (type == 'waitlist') {
      final position = event.waitlistIds.indexOf('ME') + 1; // Cannot get exact position without user ID easily here unless passed down
      // Actually we are inside builder where we filtered, but list builder doesn't know user ID easily.
      // Let's just say "候補中" or use the event status text.
      return '候補中 (${event.waitlistIds.length}人)';
    }
    return event.statusText;
  }

  Color _getStatusColor(BuildContext context, DinnerEventModel event, String type) {
    final chinguTheme = Theme.of(context).extension<ChinguTheme>();
    if (type == 'waitlist') {
      return Colors.orange;
    }
    if (event.status == EventStatus.cancelled) {
      return Colors.red;
    }
    if (type == 'history') {
      return Colors.grey;
    }
    return chinguTheme?.success ?? Colors.green;
  }
}
