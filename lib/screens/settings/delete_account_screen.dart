import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isExporting = false;
  bool _isExported = false;
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _pageController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDataExport(BuildContext context) async {
    setState(() {
      _isExporting = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).requestDataExport();
      if (mounted) {
        setState(() {
          _isExporting = false;
          _isExported = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('資料導出請求已提交，我們將在準備好後發送給您。')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('請求失敗: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.deleteAccount();

      if (mounted) {
        // 刪除成功，導向登入頁面 (通常 authProvider 狀態變化會觸發重定向，但保險起見)
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // 檢查是否需要重新登入
        if (e.toString().contains('requires-recent-login') ||
            e.toString().contains('requires recent login')) {
            showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('需要重新登入'),
              content: const Text('為了安全起見，刪除帳號前請先重新登入。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await authProvider.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  child: Text('去登入', style: TextStyle(color: theme.colorScheme.primary)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '刪除帳號',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevPage,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(context, 1, '警告', _currentPage >= 0),
                _buildStepLine(context, _currentPage >= 1),
                _buildStepIndicator(context, 2, '備份', _currentPage >= 1),
                _buildStepLine(context, _currentPage >= 2),
                _buildStepIndicator(context, 3, '確認', _currentPage >= 2),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWarningStep(context),
                _buildExportStep(context),
                _buildConfirmStep(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int step, String label, bool isActive) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(BuildContext context, bool isActive) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildWarningStep(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '這是一個永久性的操作',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號後，您將無法復原以下資料：',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildWarningItem(context, '您的個人資料和照片'),
          _buildWarningItem(context, '所有的配對紀錄和聊天訊息'),
          _buildWarningItem(context, '已報名的活動和相關紀錄'),
          _buildWarningItem(context, '所有的個人設定和偏好'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('我了解，繼續下一步'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildExportStep(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.download_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '備份您的資料？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，您可以選擇導出您的個人資料。我們會將資料打包並發送到您的電子信箱。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (!_isExported) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : () => _handleDataExport(context),
                icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download_outlined),
                label: Text(_isExporting ? '處理中...' : '導出資料'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
               ),
               child: Row(
                 children: [
                   Icon(Icons.check_circle, color: theme.colorScheme.primary),
                   const SizedBox(width: 12),
                   Expanded(child: Text('導出請求已提交，請檢查您的信箱。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary))),
                 ],
               ),
             ),
             const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isExported ? '繼續' : '略過並繼續'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '請輸入 "DELETE" 以確認刪除您的帳號。此操作無法復原。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _canDelete = value == 'DELETE';
              });
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_canDelete && !authProvider.isLoading)
                ? () => _handleDeleteAccount(context)
                : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                disabledBackgroundColor: theme.colorScheme.error.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('確認刪除帳號'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                 // 回到第一頁或直接退出
                 Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }
}
