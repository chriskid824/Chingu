import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:intl/intl.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();

  // 暫時使用固定的篩選條件
  final String _city = '台北市';
  final int _budgetRange = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 初始加載
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DinnerEventProvider>().fetchRecommendedEvents(
        city: _city,
        budgetRange: _budgetRange,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<DinnerEventProvider>().loadMoreRecommendedEvents(
        city: _city,
        budgetRange: _budgetRange,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '探索',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<DinnerEventProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.recommendedEvents.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (provider.recommendedEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暫無推薦活動',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.recommendedEvents.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.recommendedEvents.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final event = provider.recommendedEvents[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EventCard(
                  title: '6人晚餐聚會', // 這裡可以根據 event 數據動態顯示
                  date: DateFormat('yyyy/MM/dd').format(event.dateTime),
                  time: DateFormat('HH:mm').format(event.dateTime),
                  budget: 'NT\$ ${event.budgetRange == 0 ? '300-500' : event.budgetRange == 1 ? '500-800' : event.budgetRange == 2 ? '800-1200' : '1200+'} / 人',
                  location: '${event.city}${event.district}',
                  isUpcoming: true,
                  onTap: () {
                    // TODO: Navigate to event detail
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
