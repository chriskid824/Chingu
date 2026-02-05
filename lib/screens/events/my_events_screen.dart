import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
// import 'package:chingu/routes/app_router.dart'; // Assume typical route access

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
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId != null) {
        Provider.of<DinnerEventProvider>(context, listen: false).fetchMyEvents(userId);
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
    final userId = Provider.of<AuthProvider>(context).user?.uid;

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
      body: userId == null
          ? const Center(child: Text('請先登入'))
          : Consumer<DinnerEventProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = provider.myEvents;
                final now = DateTime.now();

                // 1. 已報名: 在 participantIds 中，且時間未過，且狀態未取消/完成
                final registeredEvents = events.where((e) {
                  final isParticipant = e.participantIds.contains(userId);
                  final isFuture = e.dateTime.isAfter(now);
                  final isActive = e.status != 'cancelled' && e.status != 'completed';
                  return isParticipant && isFuture && isActive;
                }).toList();

                // 2. 候補中: 在 waitlist 中
                final waitlistEvents = events.where((e) {
                  return e.waitlist.contains(userId);
                }).toList();

                // 3. 歷史紀錄: 時間已過 OR 狀態為 completed/cancelled
                final historyEvents = events.where((e) {
                   final isPast = e.dateTime.isBefore(now);
                   final isClosed = e.status == 'cancelled' || e.status == 'completed';
                   // 排除 waitlist 中的（如果過期了也算歷史嗎？通常算）
                   // 排除正在進行的已報名活動
                   return (isPast || isClosed) && !e.waitlist.contains(userId);
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(context, registeredEvents, '尚未報名任何活動', false),
                    _buildEventList(context, waitlistEvents, '目前沒有候補活動', true),
                    _buildEventList(context, historyEvents, '沒有歷史活動紀錄', false),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, String emptyMessage, bool isWaitlist) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
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
        final event = events[index];
        return _EventCard(event: event, isWaitlist: isWaitlist);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final DinnerEventModel event;
  final bool isWaitlist;

  const _EventCard({required this.event, required this.isWaitlist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('MM/dd (E) HH:mm', 'zh_TW');

    Color statusColor = theme.colorScheme.primary;
    String statusText = event.statusText;

    if (isWaitlist) {
      statusColor = chinguTheme?.warning ?? Colors.orange;
      statusText = '候補中 (${event.waitlist.indexOf('TODO_USER_ID') + 1})'; // We don't have userID here easily to show position, simplified
      statusText = '候補中';
    } else if (event.status == 'cancelled') {
      statusColor = Colors.grey;
    } else if (event.status == 'confirmed') {
      statusColor = chinguTheme?.success ?? Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/event-detail', // Use string literal or AppRoutes.eventDetail
            arguments: event.id,
          );
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    event.budgetRangeText,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('dd').format(event.dateTime),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(event.dateTime),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(event.dateTime),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${event.currentParticipants}/${event.maxParticipants} 人',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
