import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

/// 破冰話題包 — 卡片式 PageView，一次一題，左右滑動，字大
class IcebreakerScreen extends StatefulWidget {
  const IcebreakerScreen({super.key});

  @override
  State<IcebreakerScreen> createState() => _IcebreakerScreenState();
}

class _IcebreakerScreenState extends State<IcebreakerScreen> {
  int _currentPage = 0;
  late final PageController _pageController;

  // 三層級話題 — 暖場 / 深入 / 靈魂拷問
  static const _levels = [
    _TopicLevel('暖場', AppColorsMinimal.info, Icons.wb_sunny_rounded),
    _TopicLevel('深入', AppColorsMinimal.secondary, Icons.explore_rounded),
    _TopicLevel('靈魂拷問', AppColorsMinimal.primary, Icons.psychology_rounded),
  ];

  // 莫蘭迪色卡片背景
  static const _cardColors = [
    Color(0xFF6B93B8), Color(0xFF8B6F5E), Color(0xFF7A9E7E), // 暖場
    Color(0xFFA64A25), Color(0xFF8E7A6D), Color(0xFF6E8898), Color(0xFF9B7A6A), // 深入
    Color(0xFF2E5364), Color(0xFF885520), Color(0xFF6B93B8), // 靈魂拷問
  ];

  final List<Map<String, dynamic>> _questions = [
    // 暖場 (3 題)
    {'q': '你最喜歡的餐廳是哪一家？\n為什麼？', 'level': 0},
    {'q': '如果明天放假\n你會做什麼？', 'level': 0},
    {'q': '你最近追的劇或看的書\n是什麼？', 'level': 0},
    // 深入 (4 題)
    {'q': '你做過最勇敢的\n一件事是什麼？', 'level': 1},
    {'q': '有什麼事情是\n你一直想嘗試的？', 'level': 1},
    {'q': '你覺得什麼樣的人\n最值得深交？', 'level': 1},
    {'q': '如果可以回到過去\n你會改變什麼？', 'level': 1},
    // 靈魂拷問 (3 題)
    {'q': '你認為幸福的\n定義是什麼？', 'level': 2},
    {'q': '你最害怕失去\n什麼？', 'level': 2},
    {'q': '你希望別人\n怎麼記住你？', 'level': 2},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _levels[_questions[_currentPage]['level'] as int];

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Text('破冰話題包',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          )),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 層級指示
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(level.label),
              padding: const EdgeInsets.symmetric(
                horizontal: AppColorsMinimal.spaceLG,
                vertical: AppColorsMinimal.spaceSM,
              ),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(level.icon, size: 16, color: level.color),
                  const SizedBox(width: 6),
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: level.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceLG),

          // 進度指示
          Text(
            '${_currentPage + 1} / ${_questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColorsMinimal.textTertiary,
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceXL),

          // PageView 話題卡片
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final question = _questions[index];
                final cardColor = _cardColors[index % _cardColors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppColorsMinimal.spaceSM,
                    vertical: AppColorsMinimal.spaceLG,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cardColor,
                          cardColor.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppColorsMinimal.space2XL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 題號
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppColorsMinimal.space2XL),

                          // 問題文字 — 大字體，方便餐桌上大家看
                          Text(
                            question['q'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),

                          const Spacer(),

                          // 左右滑動提示
                          Text(
                            '← 左右滑動切換 →',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 底部進度條
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColorsMinimal.space3XL,
              vertical: AppColorsMinimal.spaceXL,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_questions.length, (i) {
                final isActive = i == _currentPage;
                final qLevel = _questions[i]['level'] as int;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _levels[qLevel].color
                        : AppColorsMinimal.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppColorsMinimal.spaceLG),
        ],
      ),
    );
  }
}

class _TopicLevel {
  final String label;
  final Color color;
  final IconData icon;
  const _TopicLevel(this.label, this.color, this.icon);
}
