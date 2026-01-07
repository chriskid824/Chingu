import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 配對偏好
  String _preferredMatchType = 'any';
  double _minAge = 18;
  double _maxAge = 50;
  int _budgetRange = 1;

  void _handleNextStep() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 保存步驟3的數據
    final onboardingProvider = context.read<OnboardingProvider>();
    
    // 設置配對偏好
    onboardingProvider.setPreferences(
      preferredMatchType: _preferredMatchType,
      minAge: _minAge.toInt(),
      maxAge: _maxAge.toInt(),
      budgetRange: _budgetRange,
    );

    // 導航到下一步 (地區資訊)
    Navigator.of(context).pushNamed(AppRoutes.location);
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                        gradient: index <= 2 ? chinguTheme?.primaryGradient : null,
                        color: index <= 2 ? null : theme.colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Text('步驟 3/4', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 8),
              Text(
                '配對偏好',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              
              // 配對類型
              Text(
                '配對類型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('異性配對'),
                      value: 'opposite',
                      groupValue: _preferredMatchType,
                      onChanged: (value) {
                        setState(() => _preferredMatchType = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    RadioListTile<String>(
                      title: const Text('同性配對'),
                      value: 'same',
                      groupValue: _preferredMatchType,
                      onChanged: (value) {
                        setState(() => _preferredMatchType = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    RadioListTile<String>(
                      title: const Text('不限'),
                      value: 'any',
                      groupValue: _preferredMatchType,
                      onChanged: (value) {
                        setState(() => _preferredMatchType = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 年齡範圍
              Text(
                '年齡範圍偏好',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_minAge.toInt()} - ${_maxAge.toInt()} 歲'),
                        Icon(Icons.favorite_rounded, color: theme.colorScheme.error, size: 20),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_minAge, _maxAge),
                      min: 18,
                      max: 100,
                      divisions: 82,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (values) {
                        setState(() {
                          _minAge = values.start;
                          _maxAge = values.end;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 預算範圍
              Text(
                '預算範圍',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildBudgetOption(0, 'NT\$ 300-500', theme.colorScheme.primary),
                    _buildBudgetOption(1, 'NT\$ 500-800', theme.colorScheme.primary),
                    _buildBudgetOption(2, 'NT\$ 800-1200', theme.colorScheme.primary),
                    _buildBudgetOption(3, 'NT\$ 1200+', theme.colorScheme.primary),
                  ],
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
      ),
    );
  }

  Widget _buildBudgetOption(int value, String label, Color activeColor) {
    final isSelected = _budgetRange == value;
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: _budgetRange,
      onChanged: (val) {
        setState(() => _budgetRange = val!);
      },
      activeColor: activeColor,
      selected: isSelected,
    );
  }
}
