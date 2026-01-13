import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadEvents();
      _isInit = true;
    }
  }

  Future<void> _loadEvents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId != null) {
      await Provider.of<DinnerEventProvider>(context, listen: false).fetchMyEvents(userId);
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
    final eventProvider = Provider.of<DinnerEventProvider>(context);

    // Filter events
    final now = DateTime.now();
    final allEvents = eventProvider.myEvents;

    // Upcoming: Future events, not cancelled (or pending/confirmed)
    final upcomingEvents = allEvents.where((e) =>
      e.dateTime.isAfter(now) && e.status != 'cancelled' && e.status != 'completed'
    ).toList();

    // History: Past events OR cancelled OR completed
    final historyEvents = allEvents.where((e) =>
      e.dateTime.isBefore(now) || e.status == 'cancelled' || e.status == 'completed'
    ).toList();

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
            child: eventProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildEventsList(context, upcomingEvents, true),
                      _buildEventsList(context, historyEvents, false),
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
            Icon(
              isUpcoming ? Icons.event_busy_rounded : Icons.history_rounded,
              size: 64,
              color: Theme.of(context).disabledColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '暫無即將到來的活動' : '暫無歷史活動',
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
        final dateStr = DateFormat('yyyy/MM/dd').format(event.dateTime);
        final timeStr = DateFormat('HH:mm').format(event.dateTime);

        return EventCard(
          title: '6人晚餐聚會', // Dynamic title based on event type if needed
          date: dateStr,
          time: timeStr,
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city}${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event, // Pass the model directly
            );
          },
        );
      },
    );
  }
}
