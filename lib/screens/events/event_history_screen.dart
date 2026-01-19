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

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  int _selectedIndex = 0;
  late PageController _pageController;

  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _pastEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final events = await _eventService.getUserEvents(authProvider.uid!);
      final now = DateTime.now();

      final upcoming = <DinnerEventModel>[];
      final past = <DinnerEventModel>[];

      for (var event in events) {
        if (event.dateTime.isAfter(now)) {
          upcoming.add(event);
        } else {
          past.add(event);
        }
      }

      // Sort upcoming by date (soonest first)
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Sort past by date (most recent first)
      past.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (mounted) {
        setState(() {
          _upcomingEvents = upcoming;
          _pastEvents = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
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
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventsList(context, _upcomingEvents, true),
                    _buildEventsList(context, _pastEvents, false),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> events, bool isUpcoming) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            title: '${event.participantIds.length}人晚餐聚會', // Or use confirmedCount
            date: dateFormat.format(event.dateTime),
            time: timeFormat.format(event.dateTime),
            budget: event.budgetRangeText,
            location: '${event.city} ${event.district}',
            isUpcoming: isUpcoming,
            onTap: () async {
              await Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: event.id,
              );
              _loadEvents(); // Reload on return
            },
          );
        },
      ),
    );
  }
}
