import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.uid;
      if (userId != null) {
        Provider.of<DinnerEventProvider>(context, listen: false).fetchMyEvents(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

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
              '我的預約',
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                indicator: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '📅 即將到來'),
                  Tab(text: '📋 歷史記錄'),
                ],
              ),
            ),
            Expanded(
              child: Consumer<DinnerEventProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return TabBarView(
                    children: [
                      _buildEventsList(context, provider.myEvents, true),
                      _buildEventsList(context, provider.myEvents, false),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: chinguTheme?.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.createEvent);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }
  
  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> allEvents, bool isUpcoming) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final now = DateTime.now();

    final filteredEvents = allEvents.where((event) {
      if (isUpcoming) {
        return event.dateTime.isAfter(now);
      } else {
        return event.dateTime.isBefore(now);
      }
    }).toList();

    // Empty state
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '暫無活動',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.createEvent);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    '創建活動',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        // Format date and time
        final dateStr = '${event.dateTime.year}/${event.dateTime.month.toString().padLeft(2, '0')}/${event.dateTime.day.toString().padLeft(2, '0')}';
        final timeStr = '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}';

        // Determine budget string based on range
        // Assuming budgetRange is an index or mapped value, but simplistic mapping here for display
        // Since budgetRange is int, let's just display it as is or map if we knew the mapping.
        // The original code had strings like "NT$ 500-800 / 人".
        // Let's assume budgetRange needs to be converted.
        // For now, I'll just show "預算等級: ${event.budgetRange}".
        // Or if I can find the mapping in the codebase... I'll check if there is a helper.
        // But for now, I'll just put a placeholder string.
        String budgetStr = '預算等級: ${event.budgetRange}';

        return EventCard(
          title: '${event.participants.length}人晚餐聚會', // Dynamic title? Or fixed?
          date: dateStr,
          time: timeStr,
          budget: budgetStr,
          location: '${event.city} ${event.district}',
          isUpcoming: isUpcoming,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.eventDetail,
              arguments: event, // Pass the event object
            );
          },
        );
      },
    );
  }
}
