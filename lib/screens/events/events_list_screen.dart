import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});
  
  Future<void> _handleRefresh(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;
    if (userId != null) {
      await Provider.of<DinnerEventProvider>(context, listen: false)
          .fetchMyEvents(userId);
    }
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
    );
  }
  
  Widget _buildEventsList(BuildContext context, List<DinnerEventModel> allEvents, bool isUpcoming) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final filteredEvents = allEvents.where((event) {
      if (isUpcoming) {
        return event.dateTime.isAfter(now);
      } else {
        return event.dateTime.isBefore(now);
      }
    }).toList();

    // Sort events
    filteredEvents.sort((a, b) {
      if (isUpcoming) {
        return a.dateTime.compareTo(b.dateTime); // Ascending for upcoming
      } else {
        return b.dateTime.compareTo(a.dateTime); // Descending for history
      }
    });

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      child: filteredEvents.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUpcoming ? Icons.event_busy_rounded : Icons.history_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isUpcoming ? '暫無即將到來的活動' : '暫無歷史活動',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return EventCard(
                  title: '6人晚餐聚會',
                  date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                  time: DateFormat('HH:mm').format(event.dateTime),
                  budget: event.budgetRangeText,
                  location: '${event.city}${event.district}',
                  isUpcoming: isUpcoming,
                  onTap: () {
                    // Pass event or eventId if needed by EventDetailScreen
                    // Currently EventDetailScreen might be static or expecting args
                    // Based on memory: "UserDetailScreen and EventDetailScreen do not currently consume route arguments"
                    Navigator.of(context).pushNamed(AppRoutes.eventDetail);
                  },
                );
              },
            ),
    );
  }
}
