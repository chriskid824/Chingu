import 'package:flutter/material.dart';
import 'package:chingu/screens/events/event_history_screen.dart';

// Redirect EventsListScreen to EventHistoryScreen as it is the new implementation
class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventHistoryScreen();
  }
}
