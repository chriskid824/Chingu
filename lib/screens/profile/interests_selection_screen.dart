import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/onboarding_progress_bar.dart';
import 'package:chingu/utils/interest_constants.dart';

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

  final List<Map<String, dynamic>> _categories = InterestConstants.categories;

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
    return InterestConstants.getAllInterests();
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
            const OnboardingProgressBar(
              totalSteps: 4,
              currentStep: 2,
            ),
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
