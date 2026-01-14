import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_userId == null) {
      return Scaffold(
        body: Center(
          child: Text('請先登入', style: theme.textTheme.headlineSmall),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的活動'),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: '即將參加'),
              Tab(text: '歷史活動'),
            ],
          ),
        ),
        body: FutureBuilder<List<DinnerEventModel>>(
          future: _eventService.getUserEvents(_userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('載入失敗: ${snapshot.error}'),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            final events = snapshot.data ?? [];
            final now = DateTime.now();

            final upcomingEvents = events.where((e) => e.dateTime.isAfter(now)).toList();
            final pastEvents = events.where((e) => e.dateTime.isBefore(now)).toList();

            return TabBarView(
              children: [
                _buildEventList(context, upcomingEvents, true),
                _buildEventList(context, pastEvents, false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, bool isUpcoming) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '目前沒有即將參加的活動' : '沒有歷史活動記錄',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
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
        final event = events[index];
        return EventCard(
          title: '${event.city}${event.district}晚餐', // Or generate a title
          date: '${event.dateTime.month}/${event.dateTime.day}',
          time: '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
          budget: event.budgetRangeText,
          location: event.restaurantName ?? '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event), // Will refactor DetailScreen next
              ),
            ).then((_) => setState(() {})); // Refresh on return
          },
        );
      },
    );
  }
}
