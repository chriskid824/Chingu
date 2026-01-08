import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({super.key});

  @override
  State<InterestsSelectionScreen> createState() => _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  final Set<String> _selectedInterests = {};
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'name': '休閒娛樂',
      'interests': [
        {'name': '電影', 'icon': Icons.movie_rounded},
        {'name': '音樂', 'icon': Icons.music_note_rounded},
        {'name': '遊戲', 'icon': Icons.sports_esports_rounded},
        {'name': '閱讀', 'icon': Icons.book_rounded},
        {'name': '動漫', 'icon': Icons.tv_rounded},
        {'name': '桌遊', 'icon': Icons.extension_rounded},
      ]
    },
    {
      'name': '生活風格',
      'interests': [
        {'name': '美食', 'icon': Icons.restaurant_rounded},
        {'name': '旅遊', 'icon': Icons.flight_rounded},
        {'name': '咖啡', 'icon': Icons.local_cafe_rounded},
        {'name': '寵物', 'icon': Icons.pets_rounded},
        {'name': '烹飪', 'icon': Icons.kitchen_rounded},
        {'name': '品酒', 'icon': Icons.wine_bar_rounded},
        {'name': '購物', 'icon': Icons.shopping_bag_rounded},
      ]
    },
    {
      'name': '運動健身',
      'interests': [
        {'name': '籃球', 'icon': Icons.sports_basketball_rounded},
        {'name': '健身', 'icon': Icons.fitness_center_rounded},
        {'name': '跑步', 'icon': Icons.directions_run_rounded},
        {'name': '游泳', 'icon': Icons.pool_rounded},
        {'name': '瑜珈', 'icon': Icons.self_improvement_rounded},
        {'name': '爬山', 'icon': Icons.hiking_rounded},
        {'name': '羽球', 'icon': Icons.sports_tennis_rounded},
      ]
    },
    {
      'name': '藝術創意',
      'interests': [
        {'name': '攝影', 'icon': Icons.camera_alt_rounded},
        {'name': '繪畫', 'icon': Icons.palette_rounded},
        {'name': '設計', 'icon': Icons.design_services_rounded},
        {'name': '手作', 'icon': Icons.cut_rounded},
        {'name': '寫作', 'icon': Icons.edit_rounded},
      ]
    },
    {
      'name': '科技與知識',
      'interests': [
        {'name': '科技', 'icon': Icons.computer_rounded},
        {'name': '程式設計', 'icon': Icons.code_rounded},
        {'name': '投資理財', 'icon': Icons.trending_up_rounded},
        {'name': '語言學習', 'icon': Icons.language_rounded},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allInterests {
    return _categories
        .expand((category) => category['interests'] as List<Map<String, dynamic>>)
        .toList();
  }

  void _handleNextStep() {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請至少選擇一個興趣'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // 保存步驟2的數據
    final onboardingProvider = context.read<OnboardingProvider>();
    onboardingProvider.setInterests(
      _selectedInterests.toList(),
      bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
    );

    // 導航到下一步
    Navigator.of(context).pushNamed(AppRoutes.preferences);
  }

  Widget _buildInterestChip(Map<String, dynamic> interest, ThemeData theme) {
    final isSelected = _selectedInterests.contains(interest['name']);
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            interest['icon'] as IconData,
            size: 18,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(interest['name'] as String),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedInterests.add(interest['name'] as String);
          } else {
            _selectedInterests.remove(interest['name'] as String);
          }
        });
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('完成個人資料', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: index <= 1 ? chinguTheme?.primaryGradient : null,
                      color: index <= 1 ? null : theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Text('步驟 2/4', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 8),
            Text(
              '興趣選擇',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '選擇您的興趣，讓我們為您找到志同道合的朋友',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),

            // 搜尋欄
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋興趣...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            
            // 興趣列表 (分類或搜尋結果)
            if (_searchQuery.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allInterests
                    .where((interest) => (interest['name'] as String).contains(_searchQuery))
                    .map((interest) => _buildInterestChip(interest, theme))
                    .toList(),
              ),
            ] else ...[
              ..._categories.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (category['interests'] as List<Map<String, dynamic>>)
                          .map((interest) => _buildInterestChip(interest, theme))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),
            ],
            
            if (_searchQuery.isEmpty)
              const SizedBox(height: 8) // Extra spacing if not searching
            else
              const SizedBox(height: 32),

            // 自我介紹（選填）
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: '自我介紹（選填）',
                hintText: '簡單介紹一下自己...',
                helperText: '最多 200 字',
                alignLabelWithHint: true,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 下一步按鈕
            GradientButton(
              text: '下一步',
              onPressed: _handleNextStep,
            ),
          ],
        ),
      ),
    );
  }
}
