import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _eventService = DinnerEventService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return const Center(child: Text('請先登入'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('歷史活動'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventService.getUserEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final allEvents = snapshot.data ?? [];
          // Filter for past events (history)
          // Criteria: status is completed/cancelled OR datetime is in past
          final historyEvents = allEvents.where((event) {
            final isPast = event.dateTime.isBefore(DateTime.now());
            final isFinalStatus = event.status == EventStatus.completed || event.status == EventStatus.cancelled;
            return isPast || isFinalStatus;
          }).toList();

          if (historyEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '沒有歷史活動記錄',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyEvents.length,
            itemBuilder: (context, index) {
              final event = historyEvents[index];
              final dateFormat = DateFormat('yyyy/MM/dd');
              final timeFormat = DateFormat('HH:mm');

              return EventCard(
                title: '${event.maxParticipants}人晚餐聚會',
                date: dateFormat.format(event.dateTime),
                time: timeFormat.format(event.dateTime),
                budget: '${event.budgetRangeText} / 人',
                location: '${event.city} ${event.district}',
                isUpcoming: false, // This triggers the "Completed" style in EventCard
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.eventDetail,
                    arguments: event.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
