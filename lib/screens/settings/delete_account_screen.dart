import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'dart:convert';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _confirmationController = TextEditingController();
  int _currentPage = 0;
  bool _canDelete = false;

  @override
  void dispose() {
    _pageController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await authProvider.deleteAccount();

    // Hide loading
    if (context.mounted) Navigator.of(context).pop();

    if (success) {
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '刪除帳號失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('刪除帳號'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _previousPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(context, 0, '警告'),
                _buildStepLine(context, 0),
                _buildStepIndicator(context, 1, '備份'),
                _buildStepLine(context, 1),
                _buildStepIndicator(context, 2, '確認'),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildWarningPage(context),
                _buildExportPage(context),
                _buildConfirmationPage(context),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('上一步'),
                  )
                else
                  const SizedBox.shrink(),

                if (_currentPage < 2)
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('下一步'),
                  )
                else
                  ElevatedButton(
                    onPressed: _canDelete ? () => _handleDeleteAccount(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('確認刪除'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int step, String label) {
    final theme = Theme.of(context);
    final isActive = _currentPage >= step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(BuildContext context, int step) {
    final theme = Theme.of(context);
    final isActive = _currentPage > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildWarningPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '刪除帳號是永久性的',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '如果您刪除帳號，您將無法復原。這將會刪除您的：',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildWarningItem(context, '個人資料和照片'),
          _buildWarningItem(context, '配對紀錄和聊天訊息'),
          _buildWarningItem(context, '活動紀錄和評價'),
          _buildWarningItem(context, '所有的設定偏好'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '如果您只是想暫時休息，可以考慮在設定中隱藏您的個人資料，而不是刪除帳號。',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildExportPage(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = context.read<AuthProvider>().userModel;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.file_download_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '備份您的資料',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，您可以選擇備份您的個人資料。這些資料將以 JSON 格式提供。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('用戶資料概覽', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('姓名: ${userModel?.name ?? "Unknown"}'),
                  Text('Email: ${userModel?.email ?? "Unknown"}'),
                  Text('註冊時間: ${userModel?.createdAt.toString().split('.')[0] ?? "Unknown"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (userModel != null) {
                  final data = jsonEncode(userModel.toMap());
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('資料已複製到剪貼簿')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('複製資料到剪貼簿'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.delete_forever_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '最終確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '為了確認這是您的意願，請在下方輸入 "DELETE"。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _confirmationController,
            decoration: InputDecoration(
              labelText: '輸入確認碼',
              hintText: 'DELETE',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _confirmationController.text.isNotEmpty && _confirmationController.text != 'DELETE'
                  ? '輸入內容不正確'
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _canDelete = value == 'DELETE';
              });
            },
          ),
          const SizedBox(height: 32),
          Text(
            '注意：一旦點擊刪除按鈕，您的帳號將立即被刪除且無法復原。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
