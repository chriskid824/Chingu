import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.uid != null) {
        Provider.of<DinnerEventProvider>(context, listen: false)
            .fetchMyEvents(authProvider.uid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活動歷史'),
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }

          final historyEvents = provider.myEvents.where((e) =>
             e.status == EventStatus.completed ||
             e.status == EventStatus.cancelled
          ).toList();

          // Sort desc (newest first)
          historyEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

          if (historyEvents.isEmpty) {
             return const Center(child: Text('尚無歷史活動'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyEvents.length,
            itemBuilder: (context, index) {
               final event = historyEvents[index];

               String statusText = event.statusText;
               Color statusColor;
               if (event.status == EventStatus.cancelled) {
                 statusColor = Theme.of(context).colorScheme.error;
               } else {
                 statusColor = Colors.grey;
               }

               return EventCard(
                  title: '${event.city}${event.district}晚餐',
                  date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                  time: DateFormat('HH:mm').format(event.dateTime),
                  budget: event.budgetRangeText,
                  location: '${event.city}${event.district}',
                  isUpcoming: false,
                  statusText: statusText,
                  statusColor: statusColor,
                  onTap: () {
                     Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id))
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
