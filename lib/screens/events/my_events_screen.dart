import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/routes/app_routes.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({Key? key}) : super(key: key);

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();

  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    try {
      final events = await _eventService.getUserEvents(user.uid);
      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入活動失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    if (user == null) return const Scaffold();

    // Filter events
    final now = DateTime.now();
    final registeredEvents = _allEvents.where((e) {
      final status = e.getUserRegistrationStatus(user.uid);
      return status == EventRegistrationStatus.registered &&
             e.status != 'cancelled' &&
             e.status != 'completed' &&
             e.dateTime.isAfter(now);
    }).toList();

    final waitlistEvents = _allEvents.where((e) {
      final status = e.getUserRegistrationStatus(user.uid);
      return status == EventRegistrationStatus.waitlist &&
             e.dateTime.isAfter(now);
    }).toList();

    final historyEvents = _allEvents.where((e) {
      return e.dateTime.isBefore(now) ||
             e.status == 'cancelled' ||
             e.status == 'completed';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '已報名 (${registeredEvents.length})'),
            Tab(text: '候補中 (${waitlistEvents.length})'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(registeredEvents, '尚無報名活動'),
              _buildEventList(waitlistEvents, '尚無候補活動'),
              _buildEventList(historyEvents, '尚無歷史活動'),
            ],
          ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final shouldConfirmAttendance = event.dateTime.isBefore(DateTime.now()) &&
                                        event.status != 'cancelled';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.eventDetail,
                arguments: event.id
              ).then((_) => _loadEvents()); // Reload when returning
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      _buildStatusChip(event),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${event.city} ${event.district}'),
                      const Spacer(),
                      const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(event.budgetRangeText),
                    ],
                  ),
                  if (event.restaurantName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '餐廳: ${event.restaurantName}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (shouldConfirmAttendance) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                           Navigator.pushNamed(
                              context,
                              AppRoutes.attendanceConfirmation,
                              arguments: event.id
                           );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text('確認出席 (+10分)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(DinnerEventModel event) {
    Color color;
    String text;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final userStatus = event.getUserRegistrationStatus(user!.uid);

    if (event.status == 'cancelled') {
      color = Colors.red;
      text = '已取消';
    } else if (event.dateTime.isBefore(DateTime.now())) {
      color = Colors.grey;
      text = '已結束';
    } else if (userStatus == EventRegistrationStatus.waitlist) {
      color = Colors.orange;
      text = '候補中 (第${event.waitlist.indexOf(user.uid) + 1}位)';
    } else {
      color = Colors.green;
      text = '已報名';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
