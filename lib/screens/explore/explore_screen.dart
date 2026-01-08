import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/recommended_event_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  Future<void> _fetchRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<DinnerEventProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user != null) {
      await eventProvider.fetchRecommendedEvents(
        city: user.city,
        budgetRange: user.budgetRange,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<DinnerEventProvider>(context);

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
      body: _buildBody(context, theme, authProvider, eventProvider),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AuthProvider authProvider,
    DinnerEventProvider eventProvider,
  ) {
    if (authProvider.userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eventProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eventProvider.recommendedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              '暫無推薦活動',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '我們會根據您的偏好為您尋找合適的晚餐',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
              ),
              child: const Text('重新整理'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventProvider.recommendedEvents.length,
        itemBuilder: (context, index) {
          final event = eventProvider.recommendedEvents[index];
          return RecommendedEventCard(
            title: event.restaurantName ?? '週四晚餐聚會',
            date: _formatDate(event.dateTime),
            time: _formatTime(event.dateTime),
            budget: event.budgetRangeText,
            location: '${event.city} ${event.district}',
            participantsCount: event.participantIds.length,
            onTap: () {
              // TODO: Navigate to event detail
            },
            onJoin: () {
               // TODO: Handle join event
               // Currently just a placeholder action as per task requirements
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('正在加入活動...')),
               );
               eventProvider.joinEvent(event.id, authProvider.uid!);
            },
          );
        },
      ),
    );
  }
}
