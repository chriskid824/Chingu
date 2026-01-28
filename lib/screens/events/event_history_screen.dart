import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  late Future<List<DinnerEventModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Fetch on init.
    // We need userId which we can get in build or via context in initState (but context in initState is restricted).
    // Better to fetch in didChangeDependencies or use a flag.
    // Or just check in build.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().uid;
    if (userId != null) {
      _historyFuture = _eventService.getEventHistory(userId);
    } else {
       _historyFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '活動歷史',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無活動記錄',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                title: '6人晚餐聚會', // Or dynamic title based on event
                date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                time: DateFormat('HH:mm').format(event.dateTime),
                budget: '${event.budgetRangeText} / 人',
                location: '${event.city} ${event.district}',
                isUpcoming: false,
                status: event.status,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.eventDetail,
                    arguments: {'eventId': event.id},
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
