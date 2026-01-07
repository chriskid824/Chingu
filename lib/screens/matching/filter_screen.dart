import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String _preferredMatchType;
  late RangeValues _ageRange;
  late int _budgetRange;
  bool _isLoading = false;
  bool _hasLoadedSettings = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedSettings) {
      _loadCurrentSettings();
      _hasLoadedSettings = true;
    }
  }

  void _loadCurrentSettings() {
    final user = context.read<AuthProvider>().userModel;
    
    if (user != null) {
      setState(() {
        _preferredMatchType = user.preferredMatchType;
        // 確保值在 slider 範圍內（18-100）
        final minAge = user.minAge.clamp(18, 100).toDouble();
        final maxAge = user.maxAge.clamp(18, 100).toDouble();
        _ageRange = RangeValues(minAge, maxAge);
        _budgetRange = user.budgetRange;
      });
    } else {
      setState(() {
        _preferredMatchType = 'any';
        _ageRange = const RangeValues(18, 50);
        _budgetRange = 1;
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserData({
      'preferredMatchType': _preferredMatchType,
      'minAge': _ageRange.start.toInt(),
      'maxAge': _ageRange.end.toInt(),
      'budgetRange': _budgetRange,
    });

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('篩選條件已更新'),
          backgroundColor: Theme.of(context).extension<ChinguTheme>()?.success ?? Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '更新失敗'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _preferredMatchType = 'any';
      _ageRange = const RangeValues(18, 50);
      _budgetRange = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '篩選條件',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _resetFilters,
            child: Text(
              '重置',
              style: TextStyle(
                color: chinguTheme?.surfaceVariant ?? Colors.grey, // Actually surfaceVariant is quite dark, use textTertiary logic if available or secondary
                fontWeight: FontWeight.w600,
              ), // Revert to simpler logic:
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 性別偏好
          _buildSectionTitle(Icons.people_rounded, '性別偏好', theme.colorScheme.primary, theme),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('都可以', style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text('不限性別', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: 'any',
                  groupValue: _preferredMatchType,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => _preferredMatchType = value!);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                Divider(height: 1, color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
                RadioListTile<String>(
                  title: Text('異性', style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text('只顯示異性', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: 'opposite',
                  groupValue: _preferredMatchType,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => _preferredMatchType = value!);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                Divider(height: 1, color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
                RadioListTile<String>(
                  title: Text('同性', style: TextStyle(color: theme.colorScheme.onSurface)),
                  subtitle: Text('只顯示同性', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: 'same',
                  groupValue: _preferredMatchType,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => _preferredMatchType = value!);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 年齡範圍
          _buildSectionTitle(Icons.cake_rounded, '年齡範圍', chinguTheme?.secondary ?? theme.colorScheme.secondary, theme),
          const SizedBox(height: 12),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: _isLoading ? null : (values) {
              setState(() => _ageRange = values);
            },
            activeColor: chinguTheme?.secondary ?? theme.colorScheme.secondary,
            inactiveColor: chinguTheme?.surfaceVariant ?? theme.disabledColor,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (chinguTheme?.secondary ?? theme.colorScheme.secondary).withOpacity(0.15),
                    (chinguTheme?.secondary ?? theme.colorScheme.secondary).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} 歲',
                style: TextStyle(
                  color: chinguTheme?.secondary ?? theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 預算範圍
          _buildSectionTitle(Icons.payments_rounded, '預算範圍', chinguTheme?.success ?? Colors.green, theme),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBudgetChip('NT\$ 300-500', 0, theme, chinguTheme),
              _buildBudgetChip('NT\$ 500-800', 1, theme, chinguTheme),
              _buildBudgetChip('NT\$ 800-1200', 2, theme, chinguTheme),
              _buildBudgetChip('NT\$ 1200+', 3, theme, chinguTheme),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // 套用按鈕
          Container(
            decoration: BoxDecoration(
              gradient: chinguTheme?.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '套用篩選',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(IconData icon, String title, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetChip(String label, int value, ThemeData theme, ChinguTheme? chinguTheme) {
    final selected = _budgetRange == value;
    final successColor = chinguTheme?.success ?? Colors.green;
    
    return InkWell(
      onTap: _isLoading ? null : () {
        setState(() => _budgetRange = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    successColor,
                    successColor.withOpacity(0.8),
                  ],
                )
              : null,
          color: selected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? successColor
                : (chinguTheme?.surfaceVariant ?? theme.dividerColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(Icons.check, size: 16, color: Colors.white),
            if (selected) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
