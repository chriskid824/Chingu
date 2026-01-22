import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chingu/providers/calendar_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        Provider.of<CalendarProvider>(context, listen: false)
            .loadEventsForMonth(DateTime.now(), user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活動日曆')),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              TableCalendar<DinnerEventModel>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: provider.focusedDay,
                selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
                eventLoader: provider.getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: provider.onDaySelected,
                onPageChanged: provider.onPageChanged,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        width: 7.0,
                        height: 7.0,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _buildEventList(provider.selectedDay != null
                    ? provider.getEventsForDay(provider.selectedDay!)
                    : []),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events) {
    if (events.isEmpty) {
      return const Center(child: Text('該日無活動'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.eventDetail, arguments: event.id),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(event.dateTime),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            title: Text('${event.city} ${event.district}'),
            subtitle: Text(event.statusText),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
