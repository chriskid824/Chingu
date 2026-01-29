import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().uid;
    final eventService = DinnerEventService();

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('活動記錄'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '即將參加'),
              Tab(text: '歷史活動'),
            ],
          ),
        ),
        body: FutureBuilder<List<DinnerEventModel>>(
          future: eventService.getUserEvents(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allEvents = snapshot.data ?? [];
            final upcoming = allEvents.where((e) =>
              e.dateTime.isAfter(DateTime.now()) &&
              e.status != DinnerEventStatus.cancelled
            ).toList();

            final history = allEvents.where((e) =>
              e.dateTime.isBefore(DateTime.now()) ||
              e.status == DinnerEventStatus.cancelled
            ).toList();

            return TabBarView(
              children: [
                _EventList(events: upcoming),
                _EventList(events: history),
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
        return Card(
           margin: const EdgeInsets.only(bottom: 12),
           child: ListTile(
             title: Text('${event.city}${event.district} 晚餐'),
             subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(event.dateTime)),
             trailing: Text(
               event.statusText,
               style: TextStyle(
                 color: event.status == DinnerEventStatus.cancelled ? Colors.red : null,
               ),
             ),
             onTap: () {
               Navigator.pushNamed(
                 context,
                 AppRoutes.eventDetail,
                 arguments: {'eventId': event.id},
               );
             },
           ),
        );
      },
    );
  }
}
