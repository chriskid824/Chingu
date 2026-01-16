import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _selectedIndex = 0;
  late PageController _pageController;

  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;
  String? _error;

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
    if (_userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '請先登入';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final events = await _eventService.getUserEvents(_userId);

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '載入活動失敗: $e';
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

  List<DinnerEventModel> get _upcomingEvents {
    return _allEvents.where((e) {
      final isParticipant = e.participantIds.contains(_userId);
      final isUpcoming = e.dateTime.isAfter(DateTime.now());
      final isValidStatus = e.status == 'pending' || e.status == 'confirmed';
      return isParticipant && isUpcoming && isValidStatus;
    }).toList();
  }

  List<DinnerEventModel> get _waitlistEvents {
    return _allEvents.where((e) {
      return e.waitingListIds.contains(_userId) &&
             e.dateTime.isAfter(DateTime.now()) &&
             e.status != 'cancelled';
    }).toList();
  }

  List<DinnerEventModel> get _historyEvents {
    return _allEvents.where((e) {
      final isPast = e.dateTime.isBefore(DateTime.now());
      final isCancelled = e.status == 'cancelled';
      final isCompleted = e.status == 'completed';
      return isPast || isCancelled || isCompleted;
    }).toList();
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
              tabs: const ['即將到來', '等候清單', '歷史記錄'],
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          children: [
                            _buildEventList(_upcomingEvents, '目前沒有即將到來的活動'),
                            _buildEventList(_waitlistEvents, '目前沒有排隊中的活動'),
                            _buildEventList(_historyEvents, '目前沒有歷史活動'),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final dateFormat = DateFormat('yyyy/MM/dd');
        final timeFormat = DateFormat('HH:mm');

        return EventCard(
          title: '${event.city}${event.district}晚餐聚會',
          date: dateFormat.format(event.dateTime),
          time: timeFormat.format(event.dateTime),
          budget: event.budgetRangeText,
          location: '${event.city} ${event.district}',
          isUpcoming: event.dateTime.isAfter(DateTime.now()),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event.id, // 傳遞活動 ID
            ).then((_) => _loadEvents()); // 返回時刷新
          },
        );
      },
    );
  }
}
