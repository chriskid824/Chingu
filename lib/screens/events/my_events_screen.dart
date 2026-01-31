import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:intl/intl.dart';

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

    // 初始載入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<DinnerEventProvider>().fetchMyEvents(authProvider.currentUser!.uid);
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

    // 如果沒有主題擴展，提供預設值
    final warningColor = chinguTheme?.warning ?? Colors.orange;
    final successColor = chinguTheme?.success ?? Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '候補中'),
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: Consumer2<AuthProvider, DinnerEventProvider>(
        builder: (context, authProvider, eventProvider, child) {
          if (eventProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: Text('請先登入'));
          }

          final events = eventProvider.myEvents;
          final now = DateTime.now();

          // 分類活動
          final registeredEvents = events.where((e) =>
            e.dateTime.isAfter(now) &&
            e.getUserRegistrationStatus(user.uid) == EventRegistrationStatus.registered
          ).toList();

          final waitlistEvents = events.where((e) =>
            e.dateTime.isAfter(now) &&
            e.getUserRegistrationStatus(user.uid) == EventRegistrationStatus.waitlist
          ).toList();

          final historyEvents = events.where((e) =>
            e.dateTime.isBefore(now)
          ).toList();

          // 排序：未來活動按時間近到遠，歷史活動按時間遠到近
          registeredEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          waitlistEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          historyEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(registeredEvents, '尚無已報名的活動', successColor, isWaitlist: false),
              _buildEventList(waitlistEvents, '尚無候補中的活動', warningColor, isWaitlist: true),
              _buildEventList(historyEvents, '尚無歷史活動', theme.colorScheme.secondary, isHistory: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage, Color statusColor, {bool isWaitlist = false, bool isHistory = false}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().currentUser?.uid;
        if (userId != null) {
          await context.read<DinnerEventProvider>().fetchMyEvents(userId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(context, event, statusColor, isWaitlist: isWaitlist, isHistory: isHistory);
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, DinnerEventModel event, Color statusColor, {required bool isWaitlist, required bool isHistory}) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // 導航到詳情頁
           Navigator.of(context).pushNamed(
             '/event_detail', // 假設路由名稱
             arguments: event.id, // 或 event 對象
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      isHistory
                          ? (event.status == 'cancelled' ? '已取消' : '已結束')
                          : (isWaitlist ? '候補中' : '已確認'),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
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
                  Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${event.city} ${event.district}',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isWaitlist) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '若有人取消，您將自動遞補',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ],
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
