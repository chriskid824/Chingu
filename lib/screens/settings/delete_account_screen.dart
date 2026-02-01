import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'dart:convert';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _reasons = [
    '找到伴侶了',
    '遇到技術問題',
    '隱私考量',
    '暫時休息',
    '其他原因',
  ];

  @override
  void dispose() {
    _confirmController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.deleteAccount();

      if (mounted) {
        // 刪除成功，導航到登入頁面
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('帳號已成功刪除')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleExportData() {
    final userModel = context.read<AuthProvider>().userModel;
    if (userModel == null) return;

    final userData = userModel.toMap();
    // 移除敏感或不必要的內部欄位 if needed

    final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('導出我的資料'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('您的個人資料 JSON 格式如下：'),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已複製到剪貼簿')),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('複製到剪貼簿'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConfirmed = _confirmController.text == 'DELETE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('刪除帳號'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Warning
                  _buildSectionHeader(context, '1. 重要警告', Icons.warning_amber_rounded, Colors.red),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildWarningItem(context, '此操作無法復原，您的帳號將被永久刪除。'),
                        _buildWarningItem(context, '您將失去所有的配對紀錄、聊天訊息和活動紀錄。'),
                        _buildWarningItem(context, '您的個人資料將無法被其他用戶看到。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Step 2: Data Export
                  _buildSectionHeader(context, '2. 資料備份', Icons.save_alt_rounded, colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '在刪除帳號之前，您可以導出您的個人資料備份。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _handleExportData,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('導出我的資料'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Step 3: Reason
                  _buildSectionHeader(context, '3. 離開原因（選填）', Icons.help_outline_rounded, colorScheme.secondary),
                  const SizedBox(height: 16),
                  ..._reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
                  const SizedBox(height: 32),

                  // Step 4: Confirmation
                  _buildSectionHeader(context, '4. 最終確認', Icons.check_circle_outline, colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    '請在下方輸入 "DELETE" 以確認刪除帳號。',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 40),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isConfirmed ? _handleDelete : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        disabledBackgroundColor: colorScheme.error.withOpacity(0.3),
                        disabledForegroundColor: colorScheme.onError.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '永久刪除帳號',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }
}
