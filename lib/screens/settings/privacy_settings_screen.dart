import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});
  
  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showAge = true;
  bool _showJob = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _showAge = data['privacyShowAge'] ?? true;
          _showJob = data['privacyShowJob'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String field, bool value) async {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        field: value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        children: [
          _buildSectionTitle(context, '個人資料可見性'),
          SwitchListTile(
            title: const Text('顯示年齡'),
            subtitle: Text('讓配對同伴看到您的年齡層', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _showAge,
            onChanged: (v) {
              setState(() => _showAge = v);
              _updateSetting('privacyShowAge', v);
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示職業'),
            subtitle: Text('讓配對同伴看到您的產業別', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _showJob,
            onChanged: (v) {
              setState(() => _showJob = v);
              _updateSetting('privacyShowJob', v);
            },
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '資料管理'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
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
                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('刪除帳號'),
                      content: const Text('您確定要刪除帳號嗎？所有資料將被永久刪除且無法復原。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (loadingContext) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            final authProvider = context.read<AuthProvider>();
                            final success = await authProvider.deleteAccount();
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            
                            if (success && context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('帳號已成功刪除')),
                              );
                            } else if (context.mounted) {
                              final errorMsg = authProvider.errorMessage ?? '刪除帳號失敗';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
