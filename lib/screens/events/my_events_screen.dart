import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:intl/intl.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({Key? key}) : super(key: key);

  @override
  _MyEventsScreenState createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _dinnerEventService = DinnerEventService();

  // Cache lists
  List<DinnerEventModel> _registeredEvents = [];
  List<DinnerEventModel> _historyEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final participantEvents = await _dinnerEventService.getUserEvents(user.uid);

      final now = DateTime.now();
      _registeredEvents = participantEvents.where((e) => e.dateTime.isAfter(now) && e.status != 'cancelled').toList();
      _historyEvents = participantEvents.where((e) => e.dateTime.isBefore(now) || e.status == 'cancelled').toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '候補中'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(_registeredEvents, '尚無已報名活動'),
              _EventListLoader(
                 loadEvents: () async {
                   final authService = Provider.of<AuthService>(context, listen: false);
                   if (authService.currentUser == null) return [];
                   return await _dinnerEventService.getWaitlistedEvents(authService.currentUser!.uid);
                 },
                 emptyMessage: '尚無候補活動',
              ),
              _buildEventList(_historyEvents, '尚無歷史活動'),
            ],
          ),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(DateFormat('yyyy/MM/dd HH:mm').format(event.dateTime)),
            subtitle: Text('${event.city} ${event.district}'),
            trailing: Text(event.statusText),
            onTap: () {
               Navigator.pushNamed(context, '/event_detail', arguments: event.id);
            },
          ),
        );
      },
    );
  }
}

class _EventListLoader extends StatefulWidget {
  final Future<List<DinnerEventModel>> Function() loadEvents;
  final String emptyMessage;
  const _EventListLoader({required this.loadEvents, required this.emptyMessage});

  @override
  __EventListLoaderState createState() => __EventListLoaderState();
}

class __EventListLoaderState extends State<_EventListLoader> {
  List<DinnerEventModel>? _events;

  @override
  void initState() {
    super.initState();
    widget.loadEvents().then((value) {
      if (mounted) setState(() => _events = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_events == null) return const Center(child: CircularProgressIndicator());
    if (_events!.isEmpty) return Center(child: Text(widget.emptyMessage));

    return ListView.builder(
      itemCount: _events!.length,
      itemBuilder: (context, index) {
        final event = _events![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: ListTile(
             title: Text(DateFormat('yyyy/MM/dd HH:mm').format(event.dateTime)),
             subtitle: Text('${event.city} ${event.district}'),
             trailing: Text(event.statusText),
             onTap: () {
               Navigator.pushNamed(context, '/event_detail', arguments: event.id);
             },
           ),
        );
      },
    );
  }
}
