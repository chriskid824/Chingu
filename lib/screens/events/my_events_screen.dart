import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:intl/intl.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final DinnerEventService _eventService = DinnerEventService();
  bool _isLoading = true;
  List<DinnerEventModel> _registeredEvents = [];
  List<DinnerEventModel> _waitlistedEvents = [];
  List<DinnerEventModel> _historyEvents = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadEvents();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final allUserEvents = await _eventService.getUserEvents(userId);
      final waitlisted = await _eventService.getWaitlistedEvents(userId);

      // Filter local
      final now = DateTime.now();

      _registeredEvents = allUserEvents.where((e) =>
        (e.status == 'confirmed' || e.status == 'pending') &&
        e.dateTime.isAfter(now)
      ).toList();

      _waitlistedEvents = waitlisted.where((e) => e.dateTime.isAfter(now)).toList();

      _historyEvents = allUserEvents.where((e) =>
        e.status == 'completed' ||
        e.status == 'cancelled' ||
        e.dateTime.isBefore(now)
      ).toList();

    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _showEventDialog(DinnerEventModel event) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(event: event),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '我的活動',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              tabs: const ['已報名', '候補中', '歷史'],
              selectedIndex: _selectedIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventList(_registeredEvents, '尚無報名活動', isUpcoming: true),
                    _buildEventList(_waitlistedEvents, '尚無候補活動', isWaitlist: true),
                    _buildEventList(_historyEvents, '尚無歷史活動', isHistory: true),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage, {bool isUpcoming = false, bool isWaitlist = false, bool isHistory = false}) {
    if (events.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final dateFormat = DateFormat('yyyy/MM/dd');
        final timeFormat = DateFormat('HH:mm');

        String? statusText;
        Color? statusColor;

        if (isWaitlist) {
          final userId = Provider.of<AuthProvider>(context, listen: false).uid;
          final position = event.waitingListIds.indexOf(userId ?? '') + 1;
          statusText = '候補中 ($position)';
          statusColor = Colors.orange;
        } else if (isHistory) {
             if (event.status == 'cancelled') {
               statusText = '已取消';
               statusColor = Colors.red;
             }
        }

        return EventCard(
          title: '6人晚餐聚會',
          date: dateFormat.format(event.dateTime),
          time: timeFormat.format(event.dateTime),
          budget: event.budgetRangeText,
          location: '${event.city} ${event.district}',
          isUpcoming: !isHistory,
          statusText: statusText,
          statusColor: statusColor,
          onTap: () => _showEventDialog(event),
        );
      },
    );
  }
}
