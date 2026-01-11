import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatelessWidget {
  final List<DinnerEventModel> events;

  const EventHistoryScreen({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final completedEvents = events.where((e) =>
      e.status == 'completed' ||
      e.status == 'cancelled' ||
      e.dateTime.isBefore(DateTime.now())
    ).toList();

    if (completedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暫無歷史活動',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedEvents.length,
      itemBuilder: (context, index) {
        final event = completedEvents[index];
        return EventCard(
          title: '${event.maxParticipants}人晚餐聚會',
          date: DateFormat('yyyy/MM/dd').format(event.dateTime),
          time: DateFormat('HH:mm').format(event.dateTime),
          budget: '${event.budgetRangeText} / 人',
          location: '${event.city}${event.district}',
          isUpcoming: false,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            );
          },
        );
      },
    );
  }
}
