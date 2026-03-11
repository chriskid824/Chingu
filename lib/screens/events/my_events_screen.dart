import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/animated_tab_bar.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  List<DinnerEventModel> _waitlistedEvents = [];
  bool _isLoadingWaitlist = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;
    if (userId != null) {
      // Load Registered (using Provider)
      context.read<DinnerEventProvider>().fetchMyEvents(userId);
      // Load Waitlist (local)
      _fetchWaitlist(userId);
    }
  }

  Future<void> _fetchWaitlist(String userId) async {
    if (_isLoadingWaitlist) return;
    setState(() {
      _isLoadingWaitlist = true;
    });
    try {
      final events = await DinnerEventService().getWaitlistedEvents(userId);
      if (mounted) {
        setState(() {
          _waitlistedEvents = events;
        });
      }
    } catch (e) {
      debugPrint('Error fetching waitlist: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWaitlist = false;
        });
      }
    }
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
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
            child: Consumer<DinnerEventProvider>(
              builder: (context, provider, child) {
                 if (provider.isLoading && _isLoadingWaitlist) {
                   return const Center(child: CircularProgressIndicator());
                 }

                 final now = DateTime.now();

                 // Filter Registered
                 final registeredUpcoming = provider.myEvents
                     .where((e) => e.dateTime.isAfter(now))
                     .toList();

                 // Filter Waitlist
                 final waitlistUpcoming = _waitlistedEvents
                     .where((e) => e.dateTime.isAfter(now))
                     .toList();

                 // Filter History (Both)
                 final history = [
                   ...provider.myEvents.where((e) => !e.dateTime.isAfter(now)),
                   ..._waitlistedEvents.where((e) => !e.dateTime.isAfter(now))
                 ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

                 return PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildEventList(context, registeredUpcoming, '暫無已報名活動', isWaitlist: false),
                    _buildEventList(context, waitlistUpcoming, '暫無候補活動', isWaitlist: true),
                    _buildEventList(context, history, '暫無歷史活動', isHistory: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(
      BuildContext context, List<DinnerEventModel> events, String emptyMessage,
      {bool isWaitlist = false, bool isHistory = false}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventCard(
            title: '6人晚餐聚會',
            date: DateFormat('yyyy/MM/dd').format(event.dateTime),
            time: DateFormat('HH:mm').format(event.dateTime),
            budget: event.budgetRangeText,
            location: '${event.city} ${event.district}',
            isUpcoming: !isHistory,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.eventDetail,
                arguments: {'eventId': event.id}
              );
            },
          ),
        );
      },
    );
  }
}
