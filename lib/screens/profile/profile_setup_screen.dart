import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/onboarding_progress.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇性別'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // 保存步驟1的數據
    final onboardingProvider = context.read<OnboardingProvider>();
    onboardingProvider.setBasicInfo(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender!,
      job: _jobController.text.trim(),
    );

    // 導航到下一步
    Navigator.of(context).pushNamed(AppRoutes.interestsSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Unused but kept to match surrounding code style if needed later
    // final chinguTheme = theme.extension<ChinguTheme>();

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
              // Unified Progress Indicator
              const OnboardingProgress(currentStep: 1, totalSteps: 4),
              const SizedBox(height: 8),
              Text(
                '基本資料',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              
              // 姓名
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '姓名',
                  hintText: '請輸入您的姓名',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 年齡
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '年齡',
                  hintText: '請輸入您的年齡',
                  prefixIcon: Icon(Icons.cake_rounded, color: theme.colorScheme.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入年齡';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return '請輸入有效的年齡 (18-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 性別 - Simplified to just the selection without extra box
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      '性別',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('男'),
                          value: 'male',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('女'),
                          value: 'female',
                          groupValue: _selectedGender,
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                          activeColor: theme.colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 職業
              TextFormField(
                controller: _jobController,
                decoration: InputDecoration(
                  labelText: '職業',
                  hintText: '例如：軟體工程師',
                  prefixIcon: Icon(Icons.work_outline_rounded, color: theme.colorScheme.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入職業';
                  }
                  return null;
                },
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
}
