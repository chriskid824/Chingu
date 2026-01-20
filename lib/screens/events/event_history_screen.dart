import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/enums/event_status.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/screens/events/event_detail_screen.dart';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch events when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<DinnerEventProvider>().fetchMyEvents(authProvider.user!.uid);
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
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = provider.myEvents;
          final now = DateTime.now();

          // 分類活動
          final upcomingEvents = allEvents.where((e) {
             // 狀態為 pending 或 confirmed，且時間在現在之後
             return (e.status == EventStatus.pending || e.status == EventStatus.confirmed) &&
                    e.dateTime.isAfter(now);
          }).toList();

          final pastEvents = allEvents.where((e) {
            // 狀態為 completed, cancelled 或時間在現在之前
            return e.status == EventStatus.completed ||
                   e.status == EventStatus.cancelled ||
                   e.dateTime.isBefore(now);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(context, upcomingEvents, isUpcoming: true),
              _buildEventList(context, pastEvents, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, {required bool isUpcoming}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Theme.of(context).disabledColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '目前沒有即將參加的活動' : '沒有歷史活動記錄',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).disabledColor,
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
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    Color statusColor;
    switch (event.status) {
      case EventStatus.confirmed:
        statusColor = chinguTheme?.success ?? Colors.green;
        break;
      case EventStatus.completed:
        statusColor = theme.disabledColor;
        break;
      case EventStatus.cancelled:
        statusColor = theme.colorScheme.error;
        break;
      case EventStatus.pending:
      default:
        statusColor = chinguTheme?.warning ?? Colors.orange;
    }

    // 檢查是否在候補名單
    final userId = context.read<AuthProvider>().user?.uid;
    final isWaitlisted = userId != null && event.waitingList.contains(userId);

    String statusText = event.status.label;
    if (isWaitlisted) {
      statusText = '候補中';
      statusColor = chinguTheme?.warning ?? Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                eventId: event.id,
                initialEvent: event,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.maxParticipants}人晚餐聚會',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.city} ${event.district}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(event.dateTime),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 16,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantIds.length}/${event.maxParticipants}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
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
