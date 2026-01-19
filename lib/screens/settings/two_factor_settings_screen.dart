import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/two_factor_auth_service.dart';

class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  final _twoFactorAuthService = TwoFactorAuthService();
  bool _isLoading = false;

  // Setup state
  String _selectedMethod = 'email'; // 'email' or 'sms'
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isEnabled = user.isTwoFactorEnabled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '雙因素認證 (2FA)',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, isEnabled),
            const SizedBox(height: 24),

            // Toggle Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: SwitchListTile(
                title: Text(
                  '啟用雙因素認證',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isEnabled ? '您的帳號已受保護' : '建議啟用以提升帳號安全',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: isEnabled,
                onChanged: _isLoading ? null : (value) {
                  if (value) {
                    _showSetupDialog(context, user.email, user.phoneNumber);
                  } else {
                    _disableTwoFactor(user.uid);
                  }
                },
                activeColor: theme.colorScheme.primary,
              ),
            ),

            if (isEnabled) ...[
              const SizedBox(height: 24),
              Text(
                '當前設定',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          user.twoFactorMethod == 'sms' ? Icons.sms : Icons.email,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '驗證方式',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              user.twoFactorMethod == 'sms' ? '簡訊驗證' : '電子郵件驗證',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (user.twoFactorMethod == 'sms' && user.phoneNumber != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '電話號碼',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                user.phoneNumber!,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isEnabled) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? Colors.green.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.security,
            size: 40,
            color: isEnabled ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? '2FA 已啟用' : '為什麼需要 2FA？',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? '您的帳號現在更加安全。登入時需要輸入驗證碼。'
                      : '雙因素認證為您的帳號增加了一層額外的保護，防止未經授權的存取。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disableTwoFactor(String uid) async {
    setState(() => _isLoading = true);
    try {
      await _twoFactorAuthService.disableTwoFactor(uid);
      if (mounted) {
        await context.read<AuthProvider>().refreshUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已停用雙因素認證')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSetupDialog(BuildContext context, String email, String? existingPhone) {
    // Reset state
    _selectedMethod = 'email';
    _phoneController.text = existingPhone ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '設定雙因素認證',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '選擇驗證方式',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildMethodOption(
                  context,
                  'email',
                  '電子郵件',
                  '驗證碼將發送至 $email',
                  Icons.email_outlined,
                  setState
                ),
                const SizedBox(height: 12),
                _buildMethodOption(
                  context,
                  'sms',
                  '簡訊 (SMS)',
                  '驗證碼將發送至您的手機',
                  Icons.sms_outlined,
                  setState
                ),

                if (_selectedMethod == 'sms') ...[
                  const SizedBox(height: 24),
                  Text(
                    '手機號碼',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '請輸入手機號碼 (如: 0912345678)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                ],

                const Spacer(),
                GradientButton(
                  text: '發送驗證碼',
                  onPressed: () {
                    if (_selectedMethod == 'sms' && _phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請輸入手機號碼'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _sendVerificationCodeAndVerify(
                      context,
                      _selectedMethod == 'email' ? email : _phoneController.text,
                      _selectedMethod
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildMethodOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    StateSetter setState
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v!),
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationCodeAndVerify(
    BuildContext context,
    String target,
    String method
  ) async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().userModel;
      await _twoFactorAuthService.sendVerificationCode(
        target: target,
        method: method,
        uid: user?.uid,
      );

      if (mounted) {
        _showVerificationDialog(context, target, method);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(BuildContext context, String target, String method) {
    _codeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('輸入驗證碼'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('驗證碼已發送至 $target'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final code = _codeController.text;
                if (code.length != 6) return;

                Navigator.pop(context); // Close dialog
                setState(() => _isLoading = true);

                final isValid = await _twoFactorAuthService.verifyCode(target, code);

                if (isValid) {
                  final user = context.read<AuthProvider>().userModel;
                  if (user != null) {
                    await _twoFactorAuthService.enableTwoFactor(
                      user.uid,
                      method,
                      phoneNumber: method == 'sms' ? target : null
                    );
                    await context.read<AuthProvider>().refreshUserData();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('雙因素認證已啟用！'), backgroundColor: Colors.green),
                      );
                    }
                  }
                } else {
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('驗證碼錯誤'), backgroundColor: Colors.red),
                      );
                    }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('驗證'),
          ),
        ],
      ),
    );
  }
}
