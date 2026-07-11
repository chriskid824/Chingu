import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/onboarding_progress_bar.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // 用餐偏好
  String _diningPreference = 'any';
  int _budgetRange = 1;

  bool _isSubmitting = false;

  Future<void> _handleComplete() async {
    setState(() => _isSubmitting = true);

    final onboardingProvider = context.read<OnboardingProvider>();

    // 設置配對偏好
    onboardingProvider.setPreferences(
      diningPreference: _diningPreference,
      budgetRange: _budgetRange,
    );

    // 提交所有數據到 Firestore
    final authProvider = context.read<AuthProvider>();
    final success = await onboardingProvider.submitOnboardingData(authProvider);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('個人資料設定完成！🎉'),
          backgroundColor: chinguTheme?.success ?? AppColorsMinimal.success,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.notificationPermission,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('提交失敗，請稍後再試'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
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
            // Progress Bar - Step 3 of 3
            const OnboardingProgressBar(
              totalSteps: 3,
              currentStep: 3,
            ),
            const SizedBox(height: 8),
            Text(
              '用餐偏好',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // ===== 用餐對象偏好 =====
            _buildSectionTitle('你期待和什麼樣的人一起用餐？', theme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildPreferenceOption('male', '男性為主', Icons.male_rounded, theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildPreferenceOption('female', '女性為主', Icons.female_rounded, theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildPreferenceOption('any', '都喜歡', Icons.people_rounded, theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildPreferenceOption('no_preference', '隨緣', Icons.shuffle_rounded, theme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== 預算範圍 =====
            _buildSectionTitle('預算範圍', theme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildBudgetOption(0, 'NT\$ 300-500', '小資輕食', theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildBudgetOption(1, 'NT\$ 500-800', '舒適餐敘', theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildBudgetOption(2, 'NT\$ 800-1200', '精緻饗宴', theme),
                  Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  _buildBudgetOption(3, 'NT\$ 1200+', '頂級體驗', theme),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ===== 完成按鈕 =====
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: chinguTheme?.successGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (chinguTheme?.success ?? AppColorsMinimal.success).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        '完成設定 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPreferenceOption(String value, String label, IconData icon, ThemeData theme) {
    final isSelected = _diningPreference == value;
    return ListTile(
      onTap: () => setState(() => _diningPreference = value),
      leading: Icon(icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
    );
  }

  Widget _buildBudgetOption(int value, String label, String subtitle, ThemeData theme) {
    final isSelected = _budgetRange == value;
    return ListTile(
      onTap: () => setState(() => _budgetRange = value),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
    );
  }
}
