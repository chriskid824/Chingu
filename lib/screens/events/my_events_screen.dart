import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();
  bool _isLoading = true;
  List<DinnerEventModel> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getUserEvents(userId);
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
          SnackBar(content: Text('載入失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        centerTitle: true,
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(_getRegisteredEvents()),
                _buildEventList(_getWaitlistedEvents()),
                _buildEventList(_getHistoryEvents()),
              ],
            ),
    );
  }

  List<DinnerEventModel> _getRegisteredEvents() {
    final userId = context.read<AuthProvider>().uid;
    return _allEvents.where((e) {
      final isParticipant = e.participantIds.contains(userId);
      final isPendingOrConfirmed = e.status == 'pending' || e.status == 'confirmed';
      return isParticipant && isPendingOrConfirmed && e.dateTime.isAfter(DateTime.now());
    }).toList();
  }

  List<DinnerEventModel> _getWaitlistedEvents() {
    final userId = context.read<AuthProvider>().uid;
    return _allEvents.where((e) {
      final isWaitlisted = e.waitingList.contains(userId);
      final isPending = e.status == 'pending' || e.status == 'confirmed'; // Confirmed event might still have waitlist
      return isWaitlisted && isPending && e.dateTime.isAfter(DateTime.now());
    }).toList();
  }

  List<DinnerEventModel> _getHistoryEvents() {
    // Completed, Cancelled, or Past events
    final userId = context.read<AuthProvider>().uid;
    return _allEvents.where((e) {
      // User must be participant or was in waitlist (though usually history only shows participated)
      // Let's assume history is only for participated events that are past or completed/cancelled
      final isParticipant = e.participantIds.contains(userId);
      final isPast = e.dateTime.isBefore(DateTime.now());
      final isFinishedState = e.status == 'completed' || e.status == 'cancelled';
      return isParticipant && (isPast || isFinishedState);
    }).toList();
  }

  Widget _buildEventList(List<DinnerEventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '沒有活動',
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
          return _MyEventCard(event: event);
        },
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final DinnerEventModel event;

  const _MyEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final userId = context.read<AuthProvider>().uid;

    bool isWaitlisted = event.waitingList.contains(userId);
    String statusText;
    Color statusColor;

    if (event.status == 'cancelled') {
      statusText = '已取消';
      statusColor = theme.colorScheme.error;
    } else if (event.status == 'completed') {
      statusText = '已完成';
      statusColor = Colors.grey;
    } else if (isWaitlisted) {
      final position = event.waitingList.indexOf(userId!) + 1;
      statusText = '候補順位: $position';
      statusColor = chinguTheme?.warning ?? Colors.orange;
    } else if (event.status == 'confirmed') {
      statusText = '已成團';
      statusColor = chinguTheme?.success ?? Colors.green;
    } else {
      statusText = '等待中';
      statusColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: event,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.city} ${event.district} 晚餐',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.budgetRangeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isWaitlisted)
                Text(
                  '如有空缺將自動遞補並通知您',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                 Row(
                   children: [
                     Icon(Icons.people, size: 16, color: Colors.grey[500]),
                     const SizedBox(width: 4),
                     Text(
                       '${event.currentParticipants} / ${event.maxParticipants} 人參加',
                       style: theme.textTheme.bodySmall?.copyWith(
                         color: Colors.grey[600],
                       ),
                     ),
                   ],
                 ),
            ],
          ),
        ),
      ),
    );
  }
}
