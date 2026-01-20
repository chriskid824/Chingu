import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '個人資料可見性'),
          SwitchListTile(
            title: const Text('顯示年齡'),
            subtitle: Text('讓其他用戶看到您的年齡', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示職業'),
            subtitle: Text('讓其他用戶看到您的職業', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示位置'),
            subtitle: Text('讓其他用戶看到您的大致位置', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對設定'),
          SwitchListTile(
            title: const Text('只接受已驗證用戶的配對'),
            subtitle: Text('提高配對品質', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('自動接受配對'),
            subtitle: Text('自動接受符合條件的配對請求', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '帳號安全'),
          ListTile(
            leading: Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('變更密碼'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {
              // TODO: Navigate to change password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('請使用忘記密碼功能重設')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_android, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('雙重驗證'),
            subtitle: Text(
              user?.isTwoFactorEnabled == true
                  ? '已啟用 (${user?.twoFactorMethod == 'sms' ? '簡訊' : 'Email'})'
                  : '未啟用',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () => _showTwoFactorSettings(context),
          ),
          const Divider(),
          _buildSectionTitle(context, '資料管理'),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('下載我的資料'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                title: Text(
                  '刪除帳號',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '此動作無法復原',
                  style: TextStyle(
                    color: theme.colorScheme.error.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('刪除帳號'),
                      content: const Text('您確定要刪除帳號嗎？所有資料將被永久刪除且無法復原。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement delete account logic
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('功能尚未開放')),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: const Text('刪除'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showTwoFactorSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const TwoFactorSettingsSheet(),
    );
  }
}

class TwoFactorSettingsSheet extends StatefulWidget {
  const TwoFactorSettingsSheet({super.key});

  @override
  State<TwoFactorSettingsSheet> createState() => _TwoFactorSettingsSheetState();
}

class _TwoFactorSettingsSheetState extends State<TwoFactorSettingsSheet> {
  bool _isEnabled = false;
  String _method = 'email';
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _isEnabled = user.isTwoFactorEnabled;
      _method = user.twoFactorMethod;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_method == 'sms' && _phoneController.text.isEmpty && _isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入手機號碼')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().toggleTwoFactor(
        _isEnabled,
        method: _method,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '雙重驗證設定',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('啟用雙重驗證'),
            value: _isEnabled,
            onChanged: (v) => setState(() => _isEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            const Text('驗證方式'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'email', label: Text('Email')),
                ButtonSegment(value: 'sms', label: Text('簡訊')),
              ],
              selected: {_method},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _method = newSelection.first;
                });
              },
            ),
            if (_method == 'sms') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手機號碼',
                  hintText: '0912345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('儲存設定'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
