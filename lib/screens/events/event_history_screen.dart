import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  late final DinnerEventService _eventService;
  late Future<List<DinnerEventModel>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _eventService = DinnerEventService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().user;
    if (user != null) {
      _historyFuture = _eventService.getUserEventHistory(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('歷史活動'),
        leading: const BackButton(),
      ),
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(child: Text('沒有歷史活動'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _HistoryEventCard(event: events[index]);
            },
          );
        },
      ),
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  final DinnerEventModel event;

  const _HistoryEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.completed:
        statusColor = chinguTheme?.success ?? Colors.green;
        statusText = '已完成';
        break;
      case EventStatus.cancelled:
        statusColor = Colors.red;
        statusText = '已取消';
        break;
      default:
        statusColor = Colors.grey;
        statusText = event.statusText;
    }

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
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
                    dateFormat.format(event.dateTime),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: theme.colorScheme.secondary),
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
                  Icon(Icons.people_rounded, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participantIds.length} 人參加',
                    style: theme.textTheme.bodyMedium,
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
