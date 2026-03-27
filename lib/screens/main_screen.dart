import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'home/home_screen.dart';
import 'chat/chat_list_screen.dart';
import 'events/events_screen.dart';
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatListScreen(),
    const EventsScreen(),
    const ProfileDetailScreen(),
  ];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      _bounceController.reset();
      _bounceController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColorsMinimal.background,
          boxShadow: [
            BoxShadow(
              color: AppColorsMinimal.shadowMedium,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColorsMinimal.background,
          selectedItemColor: AppColorsMinimal.primary,
          unselectedItemColor: AppColorsMinimal.textTertiary,
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
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: '首頁',
            ),
            _buildChatNavItem(),
            _buildNavItem(
              index: 2,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Events',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: isSelected
          ? AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (_, child) => Transform.scale(
                scale: _bounceAnimation.value,
                child: child,
              ),
              child: Icon(activeIcon),
            )
          : Icon(icon),
      activeIcon: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, child) => Transform.scale(
          scale: _bounceAnimation.value,
          child: child,
        ),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildChatNavItem() {
    final isSelected = _currentIndex == 1;
    return BottomNavigationBarItem(
      icon: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final badge = _buildBadgeIcon(
            context,
            Icon(isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
            chatProvider.totalUnreadCount,
          );
          if (isSelected) {
            return AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (_, child) => Transform.scale(
                scale: _bounceAnimation.value,
                child: child,
              ),
              child: badge,
            );
          }
          return badge;
        },
      ),
      activeIcon: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, child) => Transform.scale(
              scale: _bounceAnimation.value,
              child: child,
            ),
            child: _buildBadgeIcon(
              context,
              const Icon(Icons.chat_bubble_rounded),
              chatProvider.totalUnreadCount,
            ),
          );
        },
      ),
      label: '聊天',
    );
  }

  Widget _buildBadgeIcon(BuildContext context, Widget icon, int count) {
    if (count <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColorsMinimal.error,
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
