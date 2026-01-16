import 'package:flutter/material.dart';
import 'package:chingu/screens/events/my_events_screen.dart';

// 這是舊的入口，現在重定向到 MyEventsScreen
class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyEventsScreen();
  }
}
