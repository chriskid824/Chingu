import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();

  // Cache the future to prevent reloading on tab switch if using FutureBuilder directly
  // But here we might want pull-to-refresh, so we'll fetch in build or initState
  late Future<List<DinnerEventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  void _loadEvents() {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId != null) {
      _eventsFuture = _eventService.getUserEvents(userId);
    } else {
      _eventsFuture = Future.value([]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          final now = DateTime.now();

          final upcomingEvents = events.where((e) =>
            e.dateTime.isAfter(now) && e.status != EventStatus.cancelled
          ).toList();

          final pastEvents = events.where((e) =>
            e.dateTime.isBefore(now) || e.status == EventStatus.cancelled || e.status == EventStatus.completed
          ).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(upcomingEvents, isPast: false),
              _buildEventList(pastEvents, isPast: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, {required bool isPast}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isPast ? '沒有歷史活動' : '沒有即將參加的活動',
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
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: event.id, // Pass event ID
          ).then((_) => setState(() { _loadEvents(); })); // Refresh on return
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status, chinguTheme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(event.status, chinguTheme)),
                    ),
                    child: Text(
                      event.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(event.status, chinguTheme),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (event.waitlist.contains(context.read<AuthProvider>().currentUser?.uid))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '候補中',
                        style: TextStyle(fontSize: 10, color: Colors.deepOrange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(event.dateTime),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${event.city} ${event.district}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${event.participantIds.length} / ${event.maxParticipants} 人參加',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(EventStatus status, ChinguTheme? theme) {
    switch (status) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.confirmed:
        return theme?.success ?? Colors.green;
      case EventStatus.completed:
        return Colors.blue;
      case EventStatus.cancelled:
        return Colors.red;
    }
  }
}
