import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '即將到來'),
            Tab(text: '歷史活動'),
            Tab(text: '已取消'),
          ],
        ),
      ),
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventService.getUserEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('載入失敗: ${snapshot.error}'),
            );
          }

          final allEvents = snapshot.data ?? [];
          final now = DateTime.now();

          // Filter events
          final upcomingEvents = allEvents.where((e) {
            return e.status != EventStatus.cancelled &&
                   e.status != EventStatus.completed &&
                   e.dateTime.isAfter(now);
          }).toList();

          final pastEvents = allEvents.where((e) {
            return e.status == EventStatus.completed ||
                   (e.status != EventStatus.cancelled && e.dateTime.isBefore(now));
          }).toList();

          final cancelledEvents = allEvents.where((e) {
            return e.status == EventStatus.cancelled;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(upcomingEvents),
              _buildEventList(pastEvents),
              _buildEventList(cancelledEvents),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '沒有活動',
              style: TextStyle(fontSize: 18, color: Colors.grey),
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
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.pending:
        statusColor = Colors.orange;
        statusText = '等待配對';
        if (event.isFull) {
           statusText += ' (已滿)';
        }
        break;
      case EventStatus.confirmed:
        statusColor = Colors.green;
        statusText = '已確認';
        break;
      case EventStatus.completed:
        statusColor = Colors.blue;
        statusText = '已完成';
        break;
      case EventStatus.cancelled:
        statusColor = Colors.red;
        statusText = '已取消';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    event.budgetRangeText,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${event.city} ${event.district}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${event.participantIds.length} / ${event.maxParticipants} 人參加',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
