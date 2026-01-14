import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch events on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<DinnerEventProvider>().fetchMyEvents(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = provider.myEvents;
          final now = DateTime.now();

          // Filter events
          // Upcoming: Pending, Confirmed (and date is future)
          // Past: Completed, Cancelled, or date is past

          final upcomingEvents = allEvents.where((e) {
            final isFuture = e.dateTime.isAfter(now);
            final isActive = e.status == EventStatus.pending || e.status == EventStatus.confirmed;
            return isFuture && isActive;
          }).toList();

          final pastEvents = allEvents.where((e) {
            final isPast = e.dateTime.isBefore(now);
            final isInactive = e.status == EventStatus.completed || e.status == EventStatus.cancelled;
            return isPast || isInactive;
          }).toList();

          // Sort upcoming by date (closest first)
          upcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

          // Sort past by date (newest first)
          pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return TabBarView(
            controller: _tabController,
            children: [
              _EventList(events: upcomingEvents, isEmptyMessage: '沒有即將參加的活動'),
              _EventList(events: pastEvents, isEmptyMessage: '沒有歷史活動紀錄'),
            ],
          );
        },
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<DinnerEventModel> events;
  final String isEmptyMessage;

  const _EventList({required this.events, required this.isEmptyMessage});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isEmptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _EventHistoryCard(event: events[index]);
      },
    );
  }
}

class _EventHistoryCard extends StatelessWidget {
  final DinnerEventModel event;

  const _EventHistoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                eventId: event.id,
                initialEvent: event,
              ),
            ),
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
                    DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(event.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    event.restaurantName ?? '${event.city} ${event.district}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    event.budgetRangeText,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                  ),
                ],
              ),
               const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participantIds.length} / 6 人',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                  ),
                  if (event.waitlistIds.isNotEmpty) ...[
                     const SizedBox(width: 8),
                     Text(
                      '(候補: ${event.waitlistIds.length})',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EventStatus status) {
    Color color;
    String text;

    switch (status) {
      case EventStatus.pending:
        color = Colors.orange;
        text = '等待配對';
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        text = '已確認';
        break;
      case EventStatus.completed:
        color = Colors.blue;
        text = '已完成';
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        text = '已取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
