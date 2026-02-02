import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();

  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = '請先登入';
      });
      return;
    }

    try {
      final events = await _eventService.getUserEvents(userId);
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

  List<DinnerEventModel> get _upcomingEvents {
    final now = DateTime.now();
    final userId = context.read<AuthProvider>().uid;
    return _allEvents.where((e) =>
      e.dateTime.isAfter(now) &&
      e.status != EventStatus.cancelled &&
      !e.waitlistIds.contains(userId)
    ).toList();
  }

  List<DinnerEventModel> get _waitlistEvents {
    final now = DateTime.now();
    final userId = context.read<AuthProvider>().uid;
    return _allEvents.where((e) =>
      e.dateTime.isAfter(now) &&
      e.waitlistIds.contains(userId)
    ).toList();
  }

  List<DinnerEventModel> get _pastEvents {
    final now = DateTime.now();
    // Past events are those where time is past OR status is completed/cancelled
    // But we usually separate upcoming waitlist from past.
    // So past means: (time < now) OR (status == completed) OR (status == cancelled)
    // AND NOT in waitlist of future?

    // Simple logic:
    // If cancelled -> Past
    // If completed -> Past
    // If pending/confirmed AND time < now -> Past

    return _allEvents.where((e) {
      if (e.status == EventStatus.cancelled) return true;
      if (e.status == EventStatus.completed) return true;
      if (e.dateTime.isBefore(now)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '我的活動',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '即將到來'),
            Tab(text: '候補中'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('發生錯誤: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(_upcomingEvents, '目前沒有即將到來的活動'),
                    _buildEventList(_waitlistEvents, '目前沒有候補中的活動'),
                    _buildEventList(_pastEvents, '沒有歷史紀錄'),
                  ],
                ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildEventCard(context, events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    Color statusColor;
    String statusText = event.statusText;

    if (event.status == EventStatus.cancelled) {
      statusColor = Colors.red;
    } else if (event.status == EventStatus.completed) {
      statusColor = Colors.grey;
    } else if (event.status == EventStatus.confirmed) {
      statusColor = chinguTheme?.success ?? Colors.green;
    } else {
      statusColor = Colors.orange;
    }

    // 檢查是否在候補
    final userId = context.read<AuthProvider>().uid;
    if (event.waitlistIds.contains(userId)) {
      statusText = '候補中';
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.eventDetail,
            arguments: {'eventId': event.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '6人晚餐聚會',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(dateFormat.format(event.dateTime)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('${event.city} ${event.district}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(event.budgetRangeText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
