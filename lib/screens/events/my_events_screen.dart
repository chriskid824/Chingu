import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);

    // Fetch events on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<DinnerEventProvider>().fetchMyEvents(user.uid);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '候補名單'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();

          final upcomingEvents = provider.myEvents.where((e) =>
            (e.status == 'pending' || e.status == 'confirmed') && e.dateTime.isAfter(now)
          ).toList();

          final historyEvents = provider.myEvents.where((e) =>
            e.status == 'completed' || e.status == 'cancelled' || e.dateTime.isBefore(now)
          ).toList();

          final waitlistEvents = provider.myWaitlistEvents;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(context, upcomingEvents, '尚無即將參加的活動'),
              _buildEventList(context, waitlistEvents, '尚無候補中的活動'),
              _buildEventList(context, historyEvents, '尚無歷史紀錄'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: event, // Pass the event model
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status, chinguTheme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getStatusColor(event.status, chinguTheme)),
                    ),
                    child: Text(
                      event.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(event.status, chinguTheme),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    event.city,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(event.dateTime),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.monetization_on_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(event.budgetRangeText),
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('${event.confirmedCount}/${event.maxParticipants} 人'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ChinguTheme? theme) {
    switch (status) {
      case 'confirmed':
        return theme?.success ?? Colors.green;
      case 'pending':
        return theme?.warning ?? Colors.orange;
      case 'cancelled':
        return theme?.error ?? Colors.red;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
