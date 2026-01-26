import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/widgets/moment_card.dart'; // Maybe reuse a card or create a new EventCard
import 'package:intl/intl.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _dinnerEventService = DinnerEventService();
  final AuthService _authService = AuthService();
  late Future<List<DinnerEventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshEvents();
  }

  void _refreshEvents() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _eventsFuture = _dinnerEventService.getUserEvents(user.uid);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '候補名單'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: FutureBuilder<List<DinnerEventModel>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final allEvents = snapshot.data ?? [];
          final now = DateTime.now();

          // Filter events
          final upcomingEvents = allEvents.where((e) =>
            e.participantIds.contains(user.uid) &&
            e.dateTime.isAfter(now)
          ).toList();

          final waitlistEvents = allEvents.where((e) =>
            e.waitlistIds.contains(user.uid) &&
            e.dateTime.isAfter(now)
          ).toList();

          final pastEvents = allEvents.where((e) =>
            e.dateTime.isBefore(now)
          ).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(upcomingEvents, '目前沒有即將參加的活動', theme, chinguTheme, isUpcoming: true),
              _buildEventList(waitlistEvents, '目前沒有候補的活動', theme, chinguTheme),
              _buildEventList(pastEvents, '沒有歷史活動紀錄', theme, chinguTheme, isPast: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(
    List<DinnerEventModel> events,
    String emptyMessage,
    ThemeData theme,
    ChinguTheme? chinguTheme,
    {bool isUpcoming = false, bool isPast = false}
  ) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: theme.disabledColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () {
               Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: {'eventId': event.id},
              ).then((_) => _refreshEvents()); // Refresh on back
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Header Image Placeholder
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '${event.city} ${event.district} 晚餐聚會',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildDateBox(event.dateTime, theme),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               children: [
                                 Icon(Icons.people_outline, size: 16, color: theme.hintColor),
                                 const SizedBox(width: 4),
                                 Text(
                                   '${event.participantIds.length} / 6 人',
                                   style: theme.textTheme.bodyMedium,
                                 ),
                               ],
                             ),
                             const SizedBox(height: 4),
                             Row(
                               children: [
                                 Icon(Icons.monetization_on_outlined, size: 16, color: theme.hintColor),
                                 const SizedBox(width: 4),
                                 Text(
                                   event.budgetRangeText,
                                   style: theme.textTheme.bodyMedium,
                                 ),
                               ],
                             ),
                          ],
                        ),
                      ),
                      _buildStatusChip(event, theme, chinguTheme, isWaitlist: !isUpcoming && !isPast),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateBox(DateTime dateTime, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MM/dd').format(dateTime),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('HH:mm').format(dateTime),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    DinnerEventModel event,
    ThemeData theme,
    ChinguTheme? chinguTheme,
    {bool isWaitlist = false}
  ) {
    Color color;
    String text;

    if (isWaitlist) {
      color = Colors.orange;
      text = '候補中';
    } else {
      color = theme.colorScheme.primary; // Default
      text = event.statusText;

      switch(event.status.toStringValue()) {
        case 'cancelled':
          color = Colors.red;
          break;
        case 'completed':
          color = Colors.grey;
          break;
        case 'full':
          color = Colors.orange;
          break;
        case 'open':
          color = Colors.green;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
