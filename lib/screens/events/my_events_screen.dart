import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/core/routes/app_routes.dart';

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
    _tabController = TabController(length: 2, vsync: this);

    // 初始加載
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
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
    final chinguTheme = theme.extension<ChinguTheme>();
    final provider = context.watch<DinnerEventProvider>();
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox.shrink();

    // 分類活動
    final upcomingEvents = provider.myEvents.where((e) {
      // 包含已報名和候補的未來活動
      return e.dateTime.isAfter(DateTime.now()) &&
             e.status != 'cancelled' && e.status != 'completed';
    }).toList();

    final historyEvents = provider.myEvents.where((e) {
      // 過去的活動或已取消/完成的
      return e.dateTime.isBefore(DateTime.now()) ||
             e.status == 'cancelled' || e.status == 'completed';
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的活動'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '即將參加'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(context, upcomingEvents, true),
                _buildEventList(context, historyEvents, false),
              ],
            ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, bool isUpcoming) {
    if (events.isEmpty) {
      return EmptyStateWidget(
        message: isUpcoming ? '目前沒有即將參加的活動' : '尚無活動紀錄',
        buttonText: isUpcoming ? '去逛逛' : null,
        onButtonPressed: isUpcoming
            ? () => Navigator.pushNamed(context, AppRoutes.mainNavigation, arguments: {'initialIndex': 2})
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventItem(context, events[index]);
      },
    );
  }

  Widget _buildEventItem(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = context.read<AuthProvider>().user;

    // 判斷狀態
    bool isWaitlist = user != null && event.waitingList.contains(user.uid);
    bool isConfirmed = user != null && event.isUserConfirmed(user.uid);

    Color statusColor;
    String statusText;

    if (event.status == 'cancelled') {
      statusColor = theme.colorScheme.error;
      statusText = '已取消';
    } else if (event.status == 'completed') {
      statusColor = Colors.grey;
      statusText = '已完成';
    } else if (isWaitlist) {
      statusColor = chinguTheme?.warning ?? Colors.orange;
      statusText = '候補中 (${event.waitingList.indexOf(user!.uid) + 1})';
    } else if (isConfirmed) {
      statusColor = chinguTheme?.success ?? Colors.green;
      statusText = '已報名';
    } else {
      statusColor = theme.colorScheme.primary;
      statusText = event.statusText;
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${event.dateTime.month}/${event.dateTime.day} ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${event.city} ${event.district}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.restaurant_menu, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    event.restaurantName ?? '餐廳配對中...',
                    style: theme.textTheme.bodyMedium,
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
