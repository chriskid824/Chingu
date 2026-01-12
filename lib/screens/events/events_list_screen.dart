import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
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

  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _historyEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final allEvents = await _eventService.getUserEvents(userId);

      final now = DateTime.now();
      setState(() {
        _upcomingEvents = allEvents.where((e) {
          final isFuture = e.dateTime.isAfter(now);
          final isNotCancelled = e.status != EventStatus.cancelled.toStringValue();
          return isFuture && isNotCancelled;
        }).toList();

        _historyEvents = allEvents.where((e) {
           final isPast = e.dateTime.isBefore(now);
           final isCancelled = e.status == EventStatus.cancelled.toStringValue();
           return isPast || isCancelled;
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入失敗: $e')),
        );
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
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            color: theme.colorScheme.onSurface,
          )
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
              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
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
        child: Text(
          isUpcoming ? '暫無即將到來的活動' : '暫無歷史活動',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final dateFormat = DateFormat('yyyy/MM/dd', 'zh_TW');
          final timeFormat = DateFormat('HH:mm', 'zh_TW');

          return EventCard(
            title: '${event.maxParticipants}人晚餐聚會',
            date: dateFormat.format(event.dateTime),
            time: timeFormat.format(event.dateTime),
            budget: '${event.budgetRangeText} / 人',
            location: '${event.city} ${event.district}',
            isUpcoming: isUpcoming,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: event,
              ).then((_) => _loadEvents()); // Reload on return
            },
          );
        },
      ),
    );
  }
}
