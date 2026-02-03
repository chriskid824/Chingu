import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
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
            Tab(text: '等候中'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventList(
            fetcher: () => _eventService.getUserEvents(userId),
            filter: (e) => e.status != 'completed' && e.status != 'cancelled' && e.dateTime.isAfter(DateTime.now()),
            emptyMessage: '尚無即將參加的活動',
            onRefresh: _refresh,
          ),
          _EventList(
            fetcher: () => _eventService.getUserWaitlistedEvents(userId),
            filter: (e) => true,
            emptyMessage: '尚無等候中的活動',
            onRefresh: _refresh,
          ),
          _EventList(
            fetcher: () => _eventService.getUserEvents(userId),
            filter: (e) => e.status == 'completed' || e.status == 'cancelled' || e.dateTime.isBefore(DateTime.now()),
            emptyMessage: '尚無歷史活動',
            onRefresh: _refresh,
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final Future<List<DinnerEventModel>> Function() fetcher;
  final bool Function(DinnerEventModel) filter;
  final String emptyMessage;
  final VoidCallback? onRefresh;

  const _EventList({
    required this.fetcher,
    required this.filter,
    required this.emptyMessage,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DinnerEventModel>>(
      future: fetcher(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('發生錯誤: ${snapshot.error}'));
        }

        final events = snapshot.data?.where(filter).toList() ?? [];

        if (events.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(DateFormat('yyyy/MM/dd HH:mm').format(event.dateTime)),
                subtitle: Text('${event.city} ${event.district}'),
                trailing: Chip(
                  label: Text(event.statusText),
                  backgroundColor: _getStatusColor(event.status),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(eventId: event.id),
                    ),
                  );
                  onRefresh?.call();
                },
              ),
            );
          },
        );
      },
    );
  }

  Color? _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green.shade100;
      case 'pending': return Colors.orange.shade100;
      case 'cancelled': return Colors.red.shade100;
      case 'completed': return Colors.grey.shade200;
      default: return null;
    }
  }
}
