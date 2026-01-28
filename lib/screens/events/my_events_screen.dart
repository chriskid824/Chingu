import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _historyEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getUserEvents(_currentUserId);

      setState(() {
        // 分類活動
        _upcomingEvents = events.where((e) =>
          e.status == 'pending' || e.status == 'confirmed'
        ).toList();

        _historyEvents = events.where((e) =>
          e.status == 'completed' || e.status == 'cancelled'
        ).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法載入活動: $e')),
        );
      }
    }
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
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(_upcomingEvents, isHistory: false),
                _buildEventList(_historyEvents, isHistory: true),
              ],
            ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, {required bool isHistory}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isHistory ? '尚無歷史活動' : '尚無報名活動',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
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
        return _buildEventItem(event);
      },
    );
  }

  Widget _buildEventItem(DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // 判斷狀態顯示
    String statusLabel;
    Color statusColor;

    bool isWaitlisted = event.waitingListIds.contains(_currentUserId);
    bool isConfirmed = event.participantIds.contains(_currentUserId);

    if (event.status == 'cancelled') {
      statusLabel = '已取消';
      statusColor = theme.colorScheme.error;
    } else if (event.status == 'completed') {
      statusLabel = '已完成';
      statusColor = theme.colorScheme.secondary;
    } else if (isWaitlisted) {
      statusLabel = '候補中 (${event.waitingListIds.indexOf(_currentUserId) + 1})';
      statusColor = chinguTheme?.warning ?? Colors.orange;
    } else if (isConfirmed) {
      if (event.status == 'confirmed') {
        statusLabel = '成團確認';
        statusColor = chinguTheme?.success ?? Colors.green;
      } else {
        statusLabel = '已報名';
        statusColor = theme.colorScheme.primary;
      }
    } else {
      statusLabel = event.statusText;
      statusColor = theme.colorScheme.onSurface.withOpacity(0.5);
    }

    return EventCard(
      title: '6人晚餐聚會',
      date: DateFormat('yyyy/MM/dd (E)', 'zh_TW').format(event.dateTime),
      time: DateFormat('HH:mm').format(event.dateTime),
      budget: event.budgetRangeText,
      location: '${event.city} ${event.district}',
      isUpcoming: event.status != 'completed' && event.status != 'cancelled',
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () {
        // 導航到詳情頁
         Navigator.of(context).pushNamed(
           '/event-detail', // 假設這是路由名稱，之後在 router 中配置
           arguments: event.id,
         ).then((_) => _loadEvents()); // 返回時刷新
      },
    );
  }
}
