import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/services/notification_service.dart';
import 'home/home_screen.dart';
import 'matching/matching_screen.dart';
import 'explore/explore_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile/profile_detail_screen.dart';

class MainScreen extends StatefulWidget {
  final int? initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;

    // 處理應用啟動時的初始通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().processInitialMessage();
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MatchingScreen(),
    const ExploreScreen(),
    const ChatListScreen(),
    const ProfileDetailScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: chinguTheme?.shadowMedium ?? Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: '首頁',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: '配對',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: '探索',
            ),
            BottomNavigationBarItem(
              icon: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return _buildBadgeIcon(
                    context,
                    const Icon(Icons.chat_bubble_outline_rounded),
                    chatProvider.totalUnreadCount,
                  );
                },
              ),
              activeIcon: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return _buildBadgeIcon(
                    context,
                    const Icon(Icons.chat_bubble_rounded),
                    chatProvider.totalUnreadCount,
                  );
                },
              ),
              label: '聊天',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(BuildContext context, Widget icon, int count) {
    if (count <= 0) return icon;

    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
