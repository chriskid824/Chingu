import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    // Fetch events on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      if (userId != null) {
        Provider.of<DinnerEventProvider>(context, listen: false).fetchMyEvents(userId);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '我的活動',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedTabBar(
              tabs: const ['📅 即將到來', '📋 歷史記錄'],
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          Expanded(
            child: Consumer2<DinnerEventProvider, AuthProvider>(
              builder: (context, eventProvider, authProvider, child) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userId = authProvider.user?.uid;
                if (userId == null) return const Center(child: Text('請先登入'));

                final allEvents = eventProvider.myEvents;
                final now = DateTime.now();

                // Filter logic
                final upcomingEvents = allEvents.where((e) {
                  // Not cancelled AND (Future OR (Past but not completed status?? usually just check time))
                  // "History" usually means past time or cancelled.
                  // "Upcoming" means future time and active.
                  bool isCancelled = e.status == 'cancelled' ||
                      e.participantStatus[userId] == EventRegistrationStatus.cancelled.toStringValue();
                  return !isCancelled && e.dateTime.isAfter(now);
                }).toList();

                final historyEvents = allEvents.where((e) {
                   bool isCancelled = e.status == 'cancelled' ||
                      e.participantStatus[userId] == EventRegistrationStatus.cancelled.toStringValue();
                   return isCancelled || e.dateTime.isBefore(now);
                }).toList();

                // Sort
                upcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                historyEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Newest first

                return PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventList(context, upcomingEvents, userId, true),
                    _buildEventList(context, historyEvents, userId, false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<DinnerEventModel> events, String userId, bool isUpcoming) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? '沒有即將到來的活動' : '沒有歷史活動',
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
        final isWaitlisted = event.waitlist.contains(userId) ||
            event.participantStatus[userId] == EventRegistrationStatus.waitlist.toStringValue();

        // Construct status string for EventCard (or modify EventCard)
        // Since EventCard is rigid, we might need to copy/paste it or modify it.
        // For now, I'll use it as is but maybe we can tweak the logic by creating a wrapper or just modifying EventCard.
        // Actually EventCard only takes strings. But it has `isUpcoming` boolean which controls the chip color/text.
        // I will just use `isUpcoming` parameter but I really want to show "候補中" if waitlisted.

        // I will use a custom builder or a modified EventCard.
        // Let's assume I will modify EventCard to accept statusText.
        // For now, I will use the `budget` field to show Waitlist info if I can't change the status chip easily without editing EventCard.
        // Or I can modify EventCard now.

        return EventCard(
          title: '6人晚餐聚會', // TODO: dynamic title?
          date: DateFormat('yyyy/MM/dd').format(event.dateTime),
          time: DateFormat('HH:mm').format(event.dateTime),
          budget: event.budgetRangeText,
          location: '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          // We might need to pass custom status text if I modify EventCard
          // statusText: isWaitlisted ? '候補中' : (isUpcoming ? '已確認' : '已結束'),
          onTap: () {
            // Navigate to detail
            // We need to pass arguments.
             Navigator.of(context).pushNamed(
               AppRoutes.eventDetail,
               arguments: event.id, // Pass ID
             );
          },
        );
      },
    );
  }
}
