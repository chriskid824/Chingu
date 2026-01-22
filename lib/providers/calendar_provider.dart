import 'package:flutter/material.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarProvider with ChangeNotifier {
  final DinnerEventService _eventService = DinnerEventService();

  Map<DateTime, List<DinnerEventModel>> _events = {};
  Map<DateTime, List<DinnerEventModel>> get events => _events;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  DateTime? _selectedDay;
  DateTime? get selectedDay => _selectedDay;

  // Load events for a specific month (or range)
  Future<void> loadEventsForMonth(DateTime month, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would query by range.
      // DinnerEventService.getUserEvents returns all user events (sorted).
      // We can just fetch all and filter, assuming user doesn't have thousands.
      final allEvents = await _eventService.getUserEvents(userId);

      _events = {};
      for (var event in allEvents) {
        final date = DateTime(event.dateTime.year, event.dateTime.month, event.dateTime.day);
        if (_events[date] == null) {
          _events[date] = [];
        }
        _events[date]!.add(event);
      }
    } catch (e) {
      print('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  List<DinnerEventModel> getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }
}
