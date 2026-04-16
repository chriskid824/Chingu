import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import 'matching_dashboard_screen.dart';
import 'restaurant_manage_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _pages = [
    ('本週分組', Icons.groups_outlined, MatchingDashboardScreen()),
    ('餐廳管理', Icons.restaurant_outlined, RestaurantManageScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            backgroundColor: const Color(0xFF2E5364),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Chingu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '營運後台',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: '登出',
                    onPressed: () => auth.signOut(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            selectedIconTheme: const IconThemeData(color: Color(0xFFE9967A)),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFFE9967A),
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            destinations: [
              for (final p in _pages)
                NavigationRailDestination(
                  icon: Icon(p.$2),
                  label: Text(p.$1),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex].$3),
        ],
      ),
    );
  }
}
