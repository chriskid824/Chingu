import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'home_screen.dart';
import '../matching/matching_screen.dart';
import '../events/events_list_screen.dart';
import '../chat/chat_list_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // 各個Tab對應的頁面
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),              // 0: 首頁
      const MatchingScreen(),          // 1: 配對
      const EventsListScreen(),        // 2: 預約/活動
      const ChatListScreen(),          // 3: 訊息/聊天
      const SettingsScreen(),          // 4: 設定
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColorsMinimal.shadowMedium,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: AppColorsMinimal.primary,
            unselectedItemColor: AppColorsMinimal.textTertiary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home),
                label: '首頁',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                activeIcon: Icon(Icons.favorite),
                label: '配對',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded),
                activeIcon: Icon(Icons.calendar_today),
                label: '預約',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                activeIcon: Icon(Icons.chat_bubble),
                label: '訊息',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                activeIcon: Icon(Icons.settings),
                label: '設定',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
