import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/screens/events/event_detail_screen.dart'; // Assuming this exists and I'll navigate to it

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();

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
    try {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      setState(() => _isLoading = true);
      // Fetch all events related to user (registered, waitlist, etc)
      final events = await _eventService.getUserEvents(userId);

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

  List<DinnerEventModel> _getUpcomingEvents(String userId) {
    final now = DateTime.now();
    return _allEvents.where((e) {
      return e.isUserRegistered(userId) && e.dateTime.isAfter(now);
    }).toList();
  }

  List<DinnerEventModel> _getWaitlistEvents(String userId) {
    final now = DateTime.now();
    return _allEvents.where((e) {
      return e.isUserWaitlisted(userId) && e.dateTime.isAfter(now);
    }).toList();
  }

  List<DinnerEventModel> _getHistoryEvents(String userId) {
    final now = DateTime.now();
    return _allEvents.where((e) {
      final isUpcoming = e.dateTime.isAfter(now);
      final isRegistered = e.isUserRegistered(userId);
      final isWaitlist = e.isUserWaitlisted(userId);

      // If it's in the past, it's history
      if (!isUpcoming) return true;

      // If user cancelled (not registered and not waitlisted)
      // Note: getUserEvents returns events where user ID is in arrays.
      // If user cancelled, they might still be in participantIds? No, unregister removes them.
      // So getUserEvents might NOT return cancelled events unless we specifically query for them separately or keep history.
      // For now, based on current service implementation, unregister removes ID.
      // So 'History' will mostly show Past events that user participated in.

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = context.watch<AuthProvider>().user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please login'));
    }

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
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('載入失敗: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(_getUpcomingEvents(userId), '沒有即將參加的活動'),
                    _buildEventList(_getWaitlistEvents(userId), '沒有候補中的活動'),
                    _buildEventList(_getHistoryEvents(userId), '沒有歷史紀錄'),
                  ],
                ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _EventCard(event: events[index]);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final DinnerEventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('MM/dd (E) HH:mm', 'zh_TW');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.city,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(context, event),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(event.dateTime),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    event.budgetRangeText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_rounded, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '${event.currentParticipants}/${event.maxParticipants} 人',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (event.waitlistCount > 0) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.orange[300]),
                    const SizedBox(width: 6),
                    Text(
                      '候補 ${event.waitlistCount} 人',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final userId = context.read<AuthProvider>().user?.uid;

    String label = event.statusText;
    Color color = Colors.grey;

    if (userId != null) {
      if (event.isUserRegistered(userId)) {
        label = '已報名';
        color = Colors.green;
      } else if (event.isUserWaitlisted(userId)) {
        label = '候補中';
        color = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
