import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _eventService = DinnerEventService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _error = '未登入';
      });
      return;
    }

    try {
      final events = await _eventService.getUserEvents(_userId!);
      if (mounted) {
        setState(() {
          _allEvents = events;
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

  List<DinnerEventModel> _getFilteredEvents(int index) {
    final now = DateTime.now();
    switch (index) {
      case 0: // 即將到來 (已報名且未結束)
        return _allEvents.where((e) =>
          e.participantIds.contains(_userId) &&
          e.dateTime.isAfter(now) &&
          e.status != 'cancelled'
        ).toList();
      case 1: // 候補名單
        return _allEvents.where((e) =>
          e.waitingListIds.contains(_userId) &&
          e.dateTime.isAfter(now)
        ).toList();
      case 2: // 歷史紀錄 (已結束或已取消)
        return _allEvents.where((e) =>
          e.dateTime.isBefore(now) ||
          e.status == 'cancelled'
        ).toList();
      default:
        return [];
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('發生錯誤: $_error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedTabBar(
                        tabs: const ['已報名', '候補中', '歷史紀錄'],
                        selectedIndex: _selectedIndex,
                        onTabSelected: _onTabSelected,
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          _buildEventsList(_getFilteredEvents(0), true),
                          _buildEventsList(_getFilteredEvents(1), true, isWaitlist: true),
                          _buildEventsList(_getFilteredEvents(2), false),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEventsList(List<DinnerEventModel> events, bool isUpcoming, {bool isWaitlist = false}) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          isWaitlist ? '目前沒有候補中的活動' : (isUpcoming ? '目前沒有即將到來的活動' : '沒有歷史紀錄'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).hintColor,
          ),
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
          title: isWaitlist ? '候補中: 6人晚餐聚會' : '6人晚餐聚會',
          date: dateStr,
          time: timeStr,
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city}${event.district}',
          isUpcoming: isUpcoming,
          onTap: () async {
            // 傳遞 event 參數到詳情頁
            await Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event, // 傳遞完整的 EventModel
            );
            // 返回後刷新列表
            _loadEvents();
          },
        );
      },
    );
  }
}
