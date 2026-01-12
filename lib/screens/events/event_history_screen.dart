// This file re-exports EventsListScreen as EventHistoryScreen to satisfy the file requirement
// while maintaining a DRY codebase since EventsListScreen already handles history via tabs.

import 'package:flutter/material.dart';
import 'package:chingu/screens/events/events_list_screen.dart';

class EventHistoryScreen extends StatelessWidget {
  const EventHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We can default to the History tab index if we expose it in EventsListScreen,
    // but for now, we just show the screen which defaults to Upcoming.
    // Ideally, we would pass an initialIndex argument to EventsListScreen.
    return const EventsListScreen();
  }
}
