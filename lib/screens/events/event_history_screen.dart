import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _dinnerEventService = DinnerEventService();

  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _historyEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // Fetch events after build to access context/provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEvents();
    });
  }

  Future<void> _fetchEvents() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = '未登入';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final allEvents = await _dinnerEventService.getUserEvents(userId);
      final now = DateTime.now();

      final upcoming = <DinnerEventModel>[];
      final history = <DinnerEventModel>[];

      for (var event in allEvents) {
        if (event.status == EventStatus.cancelled ||
            event.status == EventStatus.completed ||
            event.dateTime.isBefore(now)) {
          history.add(event);
        } else {
          upcoming.add(event);
        }
      }

      // Sort logic is already in service but let's ensure
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // Closest first
      history.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Newest history first

      if (mounted) {
        setState(() {
          _upcomingEvents = upcoming;
          _historyEvents = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchEvents,
            color: theme.colorScheme.onSurface,
          ),
        ],
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
              : _error != null
                ? Center(child: Text('發生錯誤: $_error'))
                : PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildEventsList(context, _upcomingEvents, true),
                      _buildEventsList(context, _historyEvents, false),
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
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
              style: const TextStyle(color: Colors.grey),
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
          title: '${event.budgetRangeText} 晚餐聚會',
          date: dateStr,
          time: timeStr,
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            ).then((_) => _fetchEvents()); // Refresh on return
          },
        );
      },
    );
  }
}
