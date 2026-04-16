import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_groups_provider.dart';
import '../providers/admin_restaurants_provider.dart';
import '../widgets/group_card.dart';

class MatchingDashboardScreen extends StatefulWidget {
  const MatchingDashboardScreen({super.key});

  @override
  State<MatchingDashboardScreen> createState() => _MatchingDashboardScreenState();
}

class _MatchingDashboardScreenState extends State<MatchingDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminGroupsProvider>().loadCurrentWeek();
      context.read<AdminRestaurantsProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<AdminGroupsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('本週分組'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新整理',
            onPressed: () => groups.loadCurrentWeek(),
          ),
        ],
      ),
      body: _buildBody(groups),
    );
  }

  Widget _buildBody(AdminGroupsProvider groups) {
    if (groups.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (groups.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(groups.errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (groups.currentEventId == null) {
      return const Center(
        child: Text('本週尚無進行中的 DinnerEvent', style: TextStyle(color: Colors.black54)),
      );
    }
    if (groups.groups.isEmpty) {
      return const Center(
        child: Text('Event 已建立但尚無分組', style: TextStyle(color: Colors.black54)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event ID: ${groups.currentEventId}　|　共 ${groups.groups.length} 組',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 480,
                mainAxisExtent: 360,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: groups.groups.length,
              itemBuilder: (_, i) => GroupCard(group: groups.groups[i]),
            ),
          ),
        ],
      ),
    );
  }
}
