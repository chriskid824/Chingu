import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

/// 從設定頁進入的配對偏好編輯（獨立於 onboarding）
class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  late String _diningPreference;
  late int _budgetRange;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _diningPreference = user?.diningPreference ?? 'any';
    _budgetRange = user?.budgetRange ?? 1;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserData({
      'diningPreference': _diningPreference,
      'budgetRange': _budgetRange,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('偏好已更新 ✅'),
          backgroundColor: chinguTheme?.success ?? Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('更新失敗，請稍後再試'),
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
        title: Text('配對偏好', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 用餐對象偏好
            Text('你期待和什麼樣的人一起用餐？',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
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

            // 預算範圍
            Text('預算範圍',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
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

            // 儲存按鈕
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(_isSaving ? '儲存中...' : '儲存偏好',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceOption(String value, String label, IconData icon, ThemeData theme) {
    final isSelected = _diningPreference == value;
    return ListTile(
      onTap: () => setState(() => _diningPreference = value),
      leading: Icon(icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
    );
  }

  Widget _buildBudgetOption(int value, String label, String subtitle, ThemeData theme) {
    final isSelected = _budgetRange == value;
    return ListTile(
      onTap: () => setState(() => _budgetRange = value),
      title: Text(label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
      subtitle: Text(subtitle,
        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
    );
  }
}
