import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.uid;

    if (userId == null) {
      return const Center(child: Text('請先登入'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventList(userId, isUpcoming: true),
          _buildEventList(userId, isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildEventList(String userId, {required bool isUpcoming}) {
    return FutureBuilder<List<DinnerEventModel>>(
      future: _eventService.getUserEvents(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('發生錯誤: ${snapshot.error}'));
        }

        final allEvents = snapshot.data ?? [];
        final now = DateTime.now();

        final filteredEvents = allEvents.where((e) {
          if (isUpcoming) {
            return e.dateTime.isAfter(now) && e.status != 'cancelled';
          } else {
            return e.dateTime.isBefore(now) || e.status == 'cancelled' || e.status == 'completed';
          }
        }).toList();

        if (filteredEvents.isEmpty) {
          return Center(
            child: Text(
              isUpcoming ? '目前沒有即將參加的活動' : '沒有歷史活動記錄',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEvents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return EventCard(
              title: '${event.city} 晚餐聚會',
              date: '${event.dateTime.year}/${event.dateTime.month}/${event.dateTime.day}',
              time: '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
              budget: event.budgetRangeText,
              location: '${event.city} ${event.district}',
              isUpcoming: isUpcoming,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(eventId: event.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
