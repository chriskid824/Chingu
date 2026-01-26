import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/dinner_event_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = '未登入';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final events = await _eventService.getUserEvents(userId, includeWaitlist: true);

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DinnerEventModel> _getRegisteredEvents() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    return _allEvents.where((e) {
      final isParticipant = e.participantIds.contains(userId);
      final isFuture = e.dateTime.isAfter(now);
      final isNotCancelled = e.status != 'cancelled';
      return isParticipant && isFuture && isNotCancelled;
    }).toList();
  }

  List<DinnerEventModel> _getWaitlistEvents() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    return _allEvents.where((e) {
      final isWaitlisted = e.waitlistIds.contains(userId);
      final isFuture = e.dateTime.isAfter(now);
      final isNotCancelled = e.status != 'cancelled';
      return isWaitlisted && isFuture && isNotCancelled;
    }).toList();
  }

  List<DinnerEventModel> _getHistoryEvents() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    return _allEvents.where((e) {
      final isPast = e.dateTime.isBefore(now);
      final isCancelled = e.status == 'cancelled';
      // Include both participants and waitlisted in history if event is past/cancelled
      final isRelated = e.participantIds.contains(userId) || e.waitlistIds.contains(userId);
      return isRelated && (isPast || isCancelled);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    _buildEventList(_getRegisteredEvents(), isWaitlist: false),
                    _buildEventList(_getWaitlistEvents(), isWaitlist: true),
                    _buildEventList(_getHistoryEvents(), isWaitlist: false),
                  ],
                ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, {required bool isWaitlist}) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('沒有活動', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return DinnerEventCard(
            event: event,
            isWaitlist: isWaitlist,
            onTap: () async {
              await Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: {
                  'eventId': event.id,
                  'initialEvent': event,
                },
              );
              // Refresh on return
              _fetchEvents();
            },
          );
        },
      ),
    );
  }
}
