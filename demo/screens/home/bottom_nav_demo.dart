import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class BottomNavDemo extends StatefulWidget {
  const BottomNavDemo({super.key});
  
  @override
  State<BottomNavDemo> createState() => _BottomNavDemoState();
}

class _BottomNavDemoState extends State<BottomNavDemo> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text(
          '底部導航欄',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 大圖標展示
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: _getGradient(_currentIndex),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getColor(_currentIndex).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _getIcon(_currentIndex),
                size: 50,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 標籤
            Text(
              _getLabel(_currentIndex),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 描述
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColor(_currentIndex).withOpacity(0.15),
                    _getColor(_currentIndex).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getDescription(_currentIndex),
                style: TextStyle(
                  fontSize: 14,
                  color: _getColor(_currentIndex),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.calendar_today_rounded;
      case 2:
        return Icons.chat_bubble_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.home_rounded;
    }
  }
  
  String _getLabel(int index) {
    switch (index) {
      case 0:
        return '首頁';
      case 1:
        return '預約';
      case 2:
        return '訊息';
      case 3:
        return '我的';
      default:
        return '首頁';
    }
  }
  
  String _getDescription(int index) {
    switch (index) {
      case 0:
        return '探索精彩內容';
      case 1:
        return '管理您的晚餐預約';
      case 2:
        return '與朋友聊天';
      case 3:
        return '個人資料與設定';
      default:
        return '探索精彩內容';
    }
  }
  
  Color _getColor(int index) {
    switch (index) {
      case 0:
        return AppColorsMinimal.primary;
      case 1:
        return AppColorsMinimal.secondary;
      case 2:
        return AppColorsMinimal.success;
      case 3:
        return AppColorsMinimal.warning;
      default:
        return AppColorsMinimal.primary;
    }
  }
  
  LinearGradient _getGradient(int index) {
    final color = _getColor(index);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withOpacity(0.7),
      ],
    );
  }
}
