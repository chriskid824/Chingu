import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/core/routes/app_router.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '即將到來'),
            Tab(text: '歷史記錄'),
          ],
        ),
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = provider.myEvents;
          final userId = context.read<AuthProvider>().user?.uid ?? '';

          final upcomingEvents = allEvents.where((e) {
             final isPendingOrConfirmed = e.status == 'pending' || e.status == 'confirmed';
             // Also include if waitlisted and event not completed/cancelled
             return isPendingOrConfirmed && e.dateTime.isAfter(DateTime.now());
          }).toList();

          final historyEvents = allEvents.where((e) {
             final isCompletedOrCancelled = e.status == 'completed' || e.status == 'cancelled';
             final isPast = e.dateTime.isBefore(DateTime.now());
             return isCompletedOrCancelled || isPast;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(upcomingEvents, userId),
              _buildEventList(historyEvents, userId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String userId) {
    if (events.isEmpty) {
      return const Center(child: Text('沒有活動'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        // Determine status for card
        String statusText;
        Color? statusColor;

        if (event.status == 'cancelled') {
          statusText = '已取消';
          statusColor = Colors.grey;
        } else if (event.waitingListIds.contains(userId)) {
          statusText = '候補中 (${event.waitingListIds.indexOf(userId) + 1})';
          statusColor = Colors.orange;
        } else if (event.participantIds.contains(userId)) {
          statusText = '已報名';
          statusColor = Colors.green;
        } else {
           statusText = event.statusText;
           statusColor = null;
        }

        return EventCard(
          title: '晚餐聚會', // Or generate based on event info
          date: '${event.dateTime.year}/${event.dateTime.month}/${event.dateTime.day}',
          time: '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
          budget: event.budgetRangeText,
          location: '${event.city} ${event.district}',
          isUpcoming: event.dateTime.isAfter(DateTime.now()),
          currentParticipants: event.currentParticipants,
          maxParticipants: event.maxParticipants,
          statusText: statusText,
          statusColor: statusColor,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event.id,
            );
          },
        );
      },
    );
  }
}
