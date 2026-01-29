import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';

class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  bool _isEnabled = false;
  String _method = 'email'; // 'email' or 'sms'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userModel = context.read<AuthProvider>().userModel;
    if (userModel != null) {
      _isEnabled = userModel.isTwoFactorEnabled;
      _method = userModel.twoFactorMethod;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().updateUserData({
        'isTwoFactorEnabled': _isEnabled,
        'twoFactorMethod': _method,
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定已更新')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失敗，請稍後再試')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('發生錯誤: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('二階段驗證設定'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '啟用二階段驗證 (2FA)',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '啟用後，每次登入時除了密碼外，您還需要輸入傳送到您設備的驗證碼，以確保帳戶安全。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('啟用二階段驗證'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() => _isEnabled = value);
              },
            ),
            const Divider(height: 32),

            if (_isEnabled) ...[
              Text(
                '驗證方式',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('電子郵件'),
                subtitle: Text(userModel?.email ?? ''),
                value: 'email',
                groupValue: _method,
                onChanged: (value) {
                  setState(() => _method = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('手機簡訊 (SMS)'),
                subtitle: Text(userModel?.phoneNumber ?? '尚未設定手機號碼'),
                value: 'sms',
                groupValue: _method,
                onChanged: (value) {
                  // TODO: 如果沒有手機號碼，應該彈出對話框讓用戶輸入
                  setState(() => _method = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const Spacer(),

            GradientButton(
              text: _isLoading ? '儲存中...' : '儲存設定',
              onPressed: _isLoading ? () {} : _saveSettings,
            ),
          ],
        ),
      ),
    );
  }
}
