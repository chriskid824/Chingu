import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _dinnerEventService = DinnerEventService();
  final AuthService _authService = AuthService();

  int _selectedIndex = 0;
  late PageController _pageController;

  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _historyEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final userId = _authService.currentUser?.uid;
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

      final events = await _dinnerEventService.getUserEvents(userId);
      final now = DateTime.now();

      final upcoming = <DinnerEventModel>[];
      final history = <DinnerEventModel>[];

      for (var event in events) {
        // Logic for categorization:
        // History: Cancelled, Completed, or Past Date
        // Upcoming: Pending/Confirmed AND Future Date

        if (event.status == EventStatus.cancelled ||
            event.status == EventStatus.completed ||
            event.dateTime.isBefore(now)) {
          history.add(event);
        } else {
          upcoming.add(event);
        }
      }

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
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
            onPressed: _loadEvents,
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
                    ? Center(child: Text(_error!))
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
              isUpcoming ? Icons.event_busy_rounded : Icons.history_rounded,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '暫無即將到來的活動' : '暫無歷史記錄',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          Color statusColor;
          switch (event.status) {
            case EventStatus.confirmed:
              statusColor = chinguTheme?.success ?? Colors.green;
              break;
            case EventStatus.cancelled:
              statusColor = theme.colorScheme.error;
              break;
            case EventStatus.completed:
              statusColor = theme.colorScheme.primary;
              break;
            default: // pending
              statusColor = chinguTheme?.warning ?? Colors.orange;
          }

          return EventCard(
            title: '6人晚餐聚會', // Can be dynamic if event has title field, currently fixed in design
            date: dateFormat.format(event.dateTime),
            time: timeFormat.format(event.dateTime),
            budget: '${event.budgetRangeText} / 人',
            location: '${event.city} ${event.district}',
            isUpcoming: isUpcoming,
            statusLabel: event.statusText,
            statusColor: statusColor,
            onTap: () async {
              await Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: event.id,
              );
              _loadEvents(); // Reload when returning
            },
          );
        },
      ),
    );
  }
}
