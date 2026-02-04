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
  List<DinnerEventModel>? _upcomingEvents;
  List<DinnerEventModel>? _historyEvents;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // 使用 addPostFrameCallback 確保 context 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEvents();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      if (mounted) {
        setState(() {
          _errorMessage = '未登入';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final events = await _eventService.getUserEvents(user.uid);

      final now = DateTime.now();
      final upcoming = <DinnerEventModel>[];
      final history = <DinnerEventModel>[];

      for (var event in events) {
        if (event.dateTime.isAfter(now)) {
          upcoming.add(event);
        } else {
          history.add(event);
        }
      }

      // Sort upcoming by date ascending (nearest first)
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Sort history by date descending (newest first)
      history.sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
          _errorMessage = '載入失敗: $e';
          _isLoading = false;
        });
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
    // final chinguTheme = theme.extension<ChinguTheme>();

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          _buildEventsList(context, _upcomingEvents ?? [], true),
                          _buildEventsList(context, _historyEvents ?? [], false),
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
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史記錄',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.8),
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
          title: '${event.city}${event.district}晚餐',
          date: DateFormat('yyyy/MM/dd', 'zh_TW').format(event.dateTime),
          time: DateFormat('HH:mm', 'zh_TW').format(event.dateTime),
          budget: '${event.budgetRangeText} / 人',
          location: event.restaurantAddress ?? '${event.city}${event.district}',
          isUpcoming: isUpcoming,
          onTap: () async {
            await Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event.id,
            );
            // Return from detail might have changed state (e.g. cancelled)
            _fetchEvents();
          },
        );
      },
    );
  }
}
