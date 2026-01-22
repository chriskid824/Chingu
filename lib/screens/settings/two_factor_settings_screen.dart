import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';

class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  final _twoFactorAuthService = TwoFactorAuthService();
  bool _isEnabled = false;
  String _method = 'email';
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 確保 context 可用且 AuthProvider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user != null) {
      setState(() {
        _isEnabled = user.isTwoFactorEnabled;
        _method = user.twoFactorMethod;
        _phoneController.text = user.phoneNumber ?? '';
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.uid;

      if (uid == null) {
        throw Exception('User not logged in');
      }

      if (_isEnabled) {
        await _twoFactorAuthService.enableTwoFactor(
          uid,
          _method,
          phoneNumber: _method == 'sms' ? _phoneController.text : null,
        );
      } else {
        await _twoFactorAuthService.disableTwoFactor(uid);
      }

      // Update local user model
      await authProvider.refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定已更新')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('雙因素認證'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '雙因素認證 (2FA) 為您的帳號提供額外的安全保護。啟用後，登入時需要輸入驗證碼。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('啟用雙因素認證'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
            if (_isEnabled) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '驗證方式',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('電子郵件'),
                subtitle: const Text('發送驗證碼至您的註冊信箱'),
                value: 'email',
                groupValue: _method,
                onChanged: (value) {
                  setState(() {
                    _method = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('簡訊 (SMS)'),
                subtitle: const Text('發送驗證碼至您的手機號碼'),
                value: 'sms',
                groupValue: _method,
                onChanged: (value) {
                  setState(() {
                    _method = value!;
                  });
                },
              ),
              if (_method == 'sms') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手機號碼',
                    hintText: '請輸入手機號碼 (如: 0912345678)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 40),
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
