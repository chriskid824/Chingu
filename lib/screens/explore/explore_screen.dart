import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/event_card.dart';
import 'package:chingu/widgets/user_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _filteredEvents = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  // Mock Data
  final List<Map<String, dynamic>> _allEvents = [
    {
      'title': '週末義大利麵聚餐',
      'date': '10月24日',
      'time': '19:00',
      'budget': '800-1200 TWD',
      'location': '信義區',
      'isUpcoming': true,
    },
    {
      'title': '平日下班小酌',
      'date': '10月26日',
      'time': '20:30',
      'budget': '500-800 TWD',
      'location': '大安區',
      'isUpcoming': true,
    },
    {
      'title': '週日早午餐時光',
      'date': '10月29日',
      'time': '11:00',
      'budget': '400-600 TWD',
      'location': '中山區',
      'isUpcoming': true,
    },
     {
      'title': '咖啡品嚐會',
      'date': '11月02日',
      'time': '14:00',
      'budget': '300-500 TWD',
      'location': '松山區',
      'isUpcoming': true,
    },
  ];

  final List<Map<String, dynamic>> _allUsers = [
    {
      'name': 'Sarah',
      'age': 26,
      'job': 'UI 設計師',
      'jobIcon': Icons.brush,
      'color': Colors.pink,
      'matchScore': 95,
    },
    {
      'name': 'David',
      'age': 30,
      'job': '軟體工程師',
      'jobIcon': Icons.code,
      'color': Colors.blue,
      'matchScore': 88,
    },
    {
      'name': 'Emily',
      'age': 28,
      'job': '產品經理',
      'jobIcon': Icons.assignment,
      'color': Colors.purple,
      'matchScore': 92,
    },
    {
      'name': 'Michael',
      'age': 32,
      'job': '行銷專員',
      'jobIcon': Icons.campaign,
      'color': Colors.orange,
      'matchScore': 85,
    },
    {
      'name': 'Jessica',
      'age': 27,
      'job': '插畫家',
      'jobIcon': Icons.palette,
      'color': Colors.teal,
      'matchScore': 90,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredEvents = List.from(_allEvents);
    _filteredUsers = List.from(_allUsers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final title = event['title'].toString().toLowerCase();
        final location = event['location'].toString().toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();

      _filteredUsers = _allUsers.where((user) {
        final name = user['name'].toString().toLowerCase();
        final job = user['job'].toString().toLowerCase();
        return name.contains(query) || job.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Removed unused chinguTheme

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '探索',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130), // Increased height to prevent overflow
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋活動或用戶...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: '活動'),
                  Tab(text: '用戶'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Events Tab
          _filteredEvents.isEmpty
              ? _buildEmptyState(theme, '沒有找到相關活動')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    return EventCard(
                      title: event['title'],
                      date: event['date'],
                      time: event['time'],
                      budget: event['budget'],
                      location: event['location'],
                      isUpcoming: event['isUpcoming'],
                      onTap: () {
                        // TODO: Navigate to event detail
                      },
                    );
                  },
                ),
          // Users Tab
          _filteredUsers.isEmpty
              ? _buildEmptyState(theme, '沒有找到相關用戶')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return UserCard(
                          width: constraints.maxWidth,
                          name: user['name'],
                          age: user['age'],
                          job: user['job'],
                          jobIcon: user['jobIcon'],
                          color: user['color'],
                          matchScore: user['matchScore'],
                          onTap: () {
                             // TODO: Navigate to user profile
                          },
                        );
                      }
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
