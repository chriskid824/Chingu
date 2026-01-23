import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
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

  // Cache events
  List<DinnerEventModel> _allEvents = [];
  bool _isLoading = true;
  String? _error;

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
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _eventService.getUserEvents(_userId!);
      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<DinnerEventModel> _filterEvents(int tabIndex) {
    if (_userId == null) return [];
    final now = DateTime.now();

    return _allEvents.where((event) {
      final status = event.getUserStatus(_userId!);

      switch (tabIndex) {
        case 0: // 已報名 (Upcoming & Registered)
          return status == EventRegistrationStatus.registered &&
                 event.dateTime.isAfter(now) &&
                 event.status != 'cancelled' &&
                 event.status != 'completed';
        case 1: // 候補中 (Waitlist)
          return status == EventRegistrationStatus.waitlist &&
                 event.dateTime.isAfter(now);
        case 2: // 歷史紀錄 (Past or Cancelled or Completed)
          return event.dateTime.isBefore(now) ||
                 event.status == 'completed' ||
                 event.status == 'cancelled' ||
                 status == EventRegistrationStatus.cancelled;
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '候補中'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('發生錯誤: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(0),
                    _buildEventList(1),
                    _buildEventList(2),
                  ],
                ),
    );
  }

  Widget _buildEventList(int tabIndex) {
    final events = _filterEvents(tabIndex);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '沒有相關活動',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(
            event: event,
            currentUserId: _userId!,
            onTap: () async {
               // Navigation to detail screen would go here
               // await Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: event.id);
               // _loadEvents();
            },
            onAction: () async {
              // Show dialog
              final status = event.getUserStatus(_userId!);
              await showDialog(
                context: context,
                builder: (context) => EventRegistrationDialog(
                  event: event,
                  currentStatus: status,
                  onConfirm: () async {
                    Navigator.pop(context); // Close dialog first
                    try {
                      if (status == EventRegistrationStatus.registered || status == EventRegistrationStatus.waitlist) {
                        await _eventService.unregisterFromEvent(event.id, _userId!);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消')));
                      } else {
                        await _eventService.registerForEvent(event.id, _userId!);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已報名')));
                      }
                      _loadEvents();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final DinnerEventModel event;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _EventCard({
    required this.event,
    required this.currentUserId,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = event.getUserStatus(currentUserId);
    final dateFormat = DateFormat('MM/dd (E) HH:mm', 'zh_TW');

    Color statusColor;
    String statusText;

    switch (status) {
      case EventRegistrationStatus.registered:
        statusColor = Colors.green;
        statusText = '已報名';
        break;
      case EventRegistrationStatus.waitlist:
        statusColor = Colors.orange;
        statusText = '候補中';
        break;
      case EventRegistrationStatus.cancelled:
        statusColor = Colors.red;
        statusText = '已取消';
        break;
      default:
        statusColor = Colors.grey;
        statusText = event.statusText;
    }

    if (event.dateTime.isBefore(DateTime.now())) {
      statusColor = Colors.grey;
      statusText = '已結束';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    dateFormat.format(event.dateTime),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${event.city} ${event.district} 晚餐聚會',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(event.budgetRangeText, style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participantIds.length}/${event.maxParticipants} 人',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (status == EventRegistrationStatus.registered || status == EventRegistrationStatus.waitlist) ...[
                const SizedBox(height: 12),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(status == EventRegistrationStatus.waitlist ? '退出候補' : '取消報名'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
