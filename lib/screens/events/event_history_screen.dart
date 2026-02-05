import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/routes/app_router.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  late Future<List<DinnerEventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _eventsFuture = _eventService.getUserEvents(userId);
    } else {
      _eventsFuture = Future.value([]);
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _loadEvents();
    });
    await _eventsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: FutureBuilder<List<DinnerEventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          // Filter for past events (completed, cancelled, or time passed)
          final historyEvents = events.where((e) {
             final isPast = e.dateTime.isBefore(DateTime.now());
             return isPast || e.status == EventStatus.completed || e.status == EventStatus.cancelled;
          }).toList();

          if (historyEvents.isEmpty) {
             return ListView(
               physics: const AlwaysScrollableScrollPhysics(),
               children: const [
                 SizedBox(height: 100),
                 Center(child: Text('沒有歷史活動')),
               ],
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyEvents.length,
            itemBuilder: (context, index) {
              final event = historyEvents[index];
              return EventCard(
                title: '6人晚餐聚會', // Fixed title for now as per design
                date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                time: DateFormat('HH:mm').format(event.dateTime),
                budget: event.budgetRangeText,
                location: '${event.city} ${event.district}',
                isUpcoming: false, // History tab
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
