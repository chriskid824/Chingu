import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:chingu/widgets/event_card.dart';
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
  List<DinnerEventModel> _upcomingEvents = [];
  List<DinnerEventModel> _waitlistedEvents = [];
  List<DinnerEventModel> _historyEvents = [];

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
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Fetch all events user is participating in
      final allUserEvents = await _eventService.getUserEvents(userId);
      final waitlistedEvents = await _eventService.getUserWaitlistedEvents(userId);

      final now = DateTime.now();

      _upcomingEvents = allUserEvents.where((e) =>
        (e.status == 'pending' || e.status == 'confirmed') && e.dateTime.isAfter(now)
      ).toList();

      _historyEvents = allUserEvents.where((e) =>
        e.status == 'completed' || e.status == 'cancelled' || e.dateTime.isBefore(now)
      ).toList();

      _waitlistedEvents = waitlistedEvents;

    } catch (e) {
      debugPrint('Error loading my events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '即將參加'),
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
                _buildEventList(_upcomingEvents, '尚無即將參加的活動'),
                _buildEventList(_waitlistedEvents, '尚無候補中的活動'),
                _buildEventList(_historyEvents, '尚無歷史活動'),
              ],
            ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventCard(
            event: event,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.eventDetail,
                arguments: {'event': event},
              ).then((_) => _loadEvents()); // Reload on return
            },
          ),
        );
      },
    );
  }
}
