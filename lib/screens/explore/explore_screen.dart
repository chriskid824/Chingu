import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/user_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  final List<Map<String, dynamic>> _recommendedUsers = const [
    {
      'name': 'Sarah',
      'age': 25,
      'job': '設計師',
      'jobIcon': Icons.brush_rounded,
      'color': Colors.purple,
      'matchScore': 95,
    },
    {
      'name': 'Mike',
      'age': 28,
      'job': '工程師',
      'jobIcon': Icons.code_rounded,
      'color': Colors.blue,
      'matchScore': 88,
    },
    {
      'name': 'Emma',
      'age': 24,
      'job': '教師',
      'jobIcon': Icons.school_rounded,
      'color': Colors.orange,
      'matchScore': 92,
    },
    {
      'name': 'James',
      'age': 30,
      'job': '主廚',
      'jobIcon': Icons.restaurant_rounded,
      'color': Colors.green,
      'matchScore': 85,
    },
    {
      'name': 'Lily',
      'age': 26,
      'job': '作家',
      'jobIcon': Icons.edit_rounded,
      'color': Colors.pink,
      'matchScore': 90,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '每日精選',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '查看全部',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recommendedUsers.length,
                itemBuilder: (context, index) {
                  final user = _recommendedUsers[index];
                  return UserCard(
                    name: user['name'] as String,
                    age: user['age'] as int,
                    job: user['job'] as String,
                    jobIcon: user['jobIcon'] as IconData,
                    color: user['color'] as Color,
                    matchScore: user['matchScore'] as int,
                    onTap: () {
                      // TODO: Navigate to user profile
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Placeholder for other explore features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '更多功能即將推出',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '敬請期待更多有趣的探索功能',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }
}
