import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('活動紀錄'),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: '即將參加'),
              Tab(text: '歷史紀錄'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, List<DinnerEventModel>>>(
          future: DinnerEventService().getEventHistory(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('發生錯誤: ${snapshot.error}'));
            }

            final data = snapshot.data ?? {'upcoming': [], 'past': []};
            final upcomingEvents = data['upcoming'] ?? [];
            final pastEvents = data['past'] ?? [];

            return TabBarView(
              children: [
                _buildEventList(context, upcomingEvents, isUpcoming: true),
                _buildEventList(context, pastEvents, isUpcoming: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, {required bool isUpcoming}) {
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
              isUpcoming ? '暫無即將參加的活動' : '暫無歷史活動',
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
        return _EventCard(event: events[index]);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final DinnerEventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = event.status == EventStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(event.status).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      event.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(event.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${event.city}${event.district}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    event.budgetRangeText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (isCancelled) ...[
                 const SizedBox(height: 8),
                 Text(
                   '此活動已取消',
                   style: TextStyle(color: Colors.red, fontSize: 12),
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.confirmed:
        return Colors.green;
      case EventStatus.completed:
        return Colors.blue;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.full:
        return Colors.purple;
      case EventStatus.closed:
        return Colors.grey;
    }
  }
}
