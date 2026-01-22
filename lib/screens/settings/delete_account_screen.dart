import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/user_model.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _understandIrreversible = false;
  bool _dataBackedUp = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '刪除帳號',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Warning Text
                  Text(
                    '您確定要刪除帳號嗎？',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '刪除帳號後，您的所有資料將被永久刪除，且無法復原。這包括您的：',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(context, '個人基本資料 (匯出資料僅包含此項目)'),
                  _buildBulletPoint(context, '配對紀錄和聊天訊息'),
                  _buildBulletPoint(context, '活動參加紀錄'),
                  _buildBulletPoint(context, '信用積分和評價'),
                  const SizedBox(height: 32),

                  // Export Data Option
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              '資料備份',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '在刪除帳號前，建議您先備份您的個人資料。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _exportData(context, userModel),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('匯出個人資料 (JSON)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Confirmations
                  Text(
                    '請確認以下事項：',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCheckbox(
                    context,
                    '我了解此操作無法復原，所有資料將被永久刪除。',
                    _understandIrreversible,
                    (value) => setState(() => _understandIrreversible = value ?? false),
                  ),
                  _buildCheckbox(
                    context,
                    '我已備份資料或確認不需要備份。',
                    _dataBackedUp,
                    (value) => setState(() => _dataBackedUp = value ?? false),
                  ),
                  const SizedBox(height: 32),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_understandIrreversible && _dataBackedUp)
                          ? () => _handleDeleteAccount(context, authProvider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.3),
                      ),
                      child: const Text(
                        '確認刪除帳號',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
    BuildContext context,
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.error,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, UserModel? userModel) {
    if (userModel == null) return;

    final jsonString = const JsonEncoder.withIndent('  ').convert(userModel.toMap());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('匯出資料'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('您的資料已轉換為 JSON 格式。您可以複製並儲存。'),
            const SizedBox(height: 16),
            Container(
              height: 150,
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonString,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已複製到剪貼簿')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('複製'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, AuthProvider authProvider) async {
    // Final confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最後確認'),
        content: const Text('此操作將永久刪除您的帳號且無法復原。您確定要繼續嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await authProvider.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);

        // Handle requires-recent-login
        bool requiresRecentLogin = false;

        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          requiresRecentLogin = true;
        } else if (e.toString().contains('requires-recent-login')) {
          // Fallback check
          requiresRecentLogin = true;
        }

        if (requiresRecentLogin) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('安全驗證需要'),
              content: const Text('為了您的帳號安全，刪除帳號需要您最近有登入紀錄。\n請先登出後重新登入，然後再次嘗試刪除帳號。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    authProvider.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  child: const Text('前往登出'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }
}
