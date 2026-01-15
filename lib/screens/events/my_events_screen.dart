import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/skeleton_loader.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<DinnerEventProvider>(context, listen: false).fetchMyEvents(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DinnerEventProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '已報名'),
            Tab(text: '候補中'),
            Tab(text: '歷史紀錄'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('請先登入'))
          : provider.isLoading
              ? _buildLoading()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(
                      provider.myEvents.where((e) {
                         // Registered means participant AND not completed/cancelled yet
                         return e.participantIds.contains(user.uid) &&
                                e.status != 'completed' &&
                                e.status != 'cancelled';
                      }).toList(),
                      '您目前沒有參加任何活動',
                    ),
                    _buildEventList(
                      provider.myEvents.where((e) {
                        return e.waitingList.contains(user.uid) &&
                               e.status != 'completed' &&
                               e.status != 'cancelled';
                      }).toList(),
                      '目前沒有候補中的活動',
                    ),
                    _buildEventList(
                      provider.myEvents.where((e) {
                        return e.status == 'completed' || e.status == 'cancelled';
                      }).toList(),
                      '沒有歷史活動紀錄',
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const SkeletonEventCard(),
    );
  }

  Widget _buildEventList(List<DinnerEventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.event_busy_rounded,
          title: '沒有活動',
          message: emptyMessage,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(event: event);
      },
    );
  }
}
