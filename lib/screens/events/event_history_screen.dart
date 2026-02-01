import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  late Future<List<DinnerEventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final userId = Provider.of<AuthProvider>(context, listen: false).uid;
    if (userId != null) {
      _eventsFuture = DinnerEventService().getEventHistory(userId);
    } else {
      _eventsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We can verify user is logged in
    final userId = Provider.of<AuthProvider>(context).uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('活動記錄'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '即將到來'),
              Tab(text: '歷史記錄'),
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
              return Center(child: Text('發生錯誤: ${snapshot.error}'));
            }

            final events = snapshot.data ?? [];
            final now = DateTime.now();

            final upcomingEvents = events.where((e) =>
              e.dateTime.isAfter(now) && e.status != 'cancelled'
            ).toList();

            final pastEvents = events.where((e) =>
              e.dateTime.isBefore(now) || e.status == 'cancelled'
            ).toList();

            return TabBarView(
              children: [
                _EventList(events: upcomingEvents),
                _EventList(events: pastEvents),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<DinnerEventModel> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('沒有活動記錄'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event);
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: {'eventId': event.id},
          );
        },
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('${event.city} ${event.district}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('${event.participantIds.length} / ${event.maxParticipants} 人'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
