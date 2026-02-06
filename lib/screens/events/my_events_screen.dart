import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/dinner_event_model.dart';
import '../../services/dinner_event_service.dart';
import '../../core/routes/app_routes.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({Key? key}) : super(key: key);

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DinnerEventService _eventService = DinnerEventService();
  late String _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
    } else {
      // Handle unauthenticated state if necessary
      _userId = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: '歷史活動'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventList(
            userId: _userId,
            filterType: 'upcoming',
            eventService: _eventService,
            emptyMessage: '尚無已報名的活動',
          ),
          _EventList(
            userId: _userId,
            filterType: 'waitlist',
            eventService: _eventService,
            emptyMessage: '尚無候補中的活動',
          ),
          _EventList(
            userId: _userId,
            filterType: 'history',
            eventService: _eventService,
            emptyMessage: '尚無歷史活動',
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final String userId;
  final String filterType;
  final DinnerEventService eventService;
  final String emptyMessage;

  const _EventList({
    Key? key,
    required this.userId,
    required this.filterType,
    required this.eventService,
    required this.emptyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Center(child: Text('請先登入'));
    }

    return FutureBuilder<List<DinnerEventModel>>(
      future: eventService.getUserEvents(userId, filterType: filterType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('發生錯誤: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return ListView.builder(
          itemCount: events.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventCard(
              event: event,
              isWaitlist: filterType == 'waitlist' || (userId.isNotEmpty && event.isUserWaitlisted(userId)),
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final DinnerEventModel event;
  final bool isWaitlist;

  const _EventCard({
    Key? key,
    required this.event,
    this.isWaitlist = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
           // Navigate using route name if args supported, else pass object if route allows
           // Since EventDetailScreen usually takes ID or Model, we try to pass arguments
           Navigator.pushNamed(
             context,
             AppRoutes.eventDetail,
             arguments: event, // Assuming EventDetailScreen accepts DinnerEventModel as argument
           );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.city} ${event.district}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _StatusBadge(status: event.status, isWaitlist: isWaitlist),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(event.dateTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '預算: ${event.budgetRangeText}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isWaitlist;

  const _StatusBadge({Key? key, required this.status, required this.isWaitlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (isWaitlist) {
      color = Colors.orange;
      text = '候補中';
    } else {
      switch (status) {
        case 'pending':
          color = Colors.blue;
          text = '等待配對';
          break;
        case 'confirmed':
          color = Colors.green;
          text = '已確認';
          break;
        case 'completed':
          color = Colors.grey;
          text = '已完成';
          break;
        case 'cancelled':
          color = Colors.red;
          text = '已取消';
          break;
        default:
          color = Colors.grey;
          text = status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
