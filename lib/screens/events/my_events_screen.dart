import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _dinnerEventService = DinnerEventService();
  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final events = await _dinnerEventService.getUserEvents(userId);
      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加載失敗: $e')),
        );
      }
    }
  }

  List<DinnerEventModel> _getEventsByTab(int tabIndex, String userId) {
    switch (tabIndex) {
      case 0: // Upcoming (Registered)
        return _allEvents.where((e) {
          final isRegistered = e.participantIds.contains(userId);
          final isUpcoming = e.dateTime.isAfter(DateTime.now());
          final isNotCancelled = e.status != 'cancelled';
          return isRegistered && isUpcoming && isNotCancelled;
        }).toList();
      case 1: // Waitlist
        return _allEvents.where((e) {
          return e.waitlist.contains(userId) && e.dateTime.isAfter(DateTime.now());
        }).toList();
      case 2: // Past
        return _allEvents.where((e) {
          final isPast = e.dateTime.isBefore(DateTime.now());
          final isCancelled = e.status == 'cancelled';
          // Past events include registered/waitlist that are over, OR cancelled events
          // Usually past events are just ones where date is past.
          return isPast || isCancelled;
        }).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final userId = Provider.of<AuthProvider>(context).user?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '候補中'),
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(context, _getEventsByTab(0, userId), 'registered', chinguTheme),
                _buildEventList(context, _getEventsByTab(1, userId), 'waitlist', chinguTheme),
                _buildEventList(context, _getEventsByTab(2, userId), 'past', chinguTheme),
              ],
            ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, String type, ChinguTheme? chinguTheme) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              '沒有活動',
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
            ),
          ],
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
          String statusText;
          Color statusColor;

          if (type == 'registered') {
            statusText = '已確認';
            statusColor = chinguTheme?.success ?? Colors.green;
          } else if (type == 'waitlist') {
            statusText = '候補中 (${event.waitlist.indexOf(event.waitlist.firstWhere((id) => true, orElse: () => '')) + 1})'; // Simplified rank
            statusColor = chinguTheme?.warning ?? Colors.orange;
          } else {
             if (event.status == 'cancelled') {
               statusText = '已取消';
               statusColor = Theme.of(context).colorScheme.error;
             } else if (event.status == 'completed') {
               statusText = '已完成';
               statusColor = Colors.blue;
             } else {
               statusText = '已結束';
               statusColor = Colors.grey;
             }
          }

          return EventCard(
            title: '${event.maxParticipants}人晚餐聚會',
            date: DateFormat('yyyy/MM/dd').format(event.dateTime),
            time: DateFormat('HH:mm').format(event.dateTime),
            budget: event.budgetRangeText,
            location: '${event.city} ${event.district}',
            isUpcoming: type != 'past',
            statusText: statusText,
            statusColor: statusColor,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
              );
              _loadEvents(); // Refresh after returning
            },
          );
        },
      ),
    );
  }
}
