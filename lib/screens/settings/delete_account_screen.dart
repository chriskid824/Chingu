import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedReason;
  bool _isConfirmed = false;
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _reasons = [
    '找不到合適的對象',
    '遇到技術問題',
    '想要休息一下',
    '已經找到伴侶',
    '隱私顧慮',
    '其他',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleDeleteAccount() async {
    if (!_isConfirmed) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 再次確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最後警告'),
        content: const Text('您確定要永久刪除帳號嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await authProvider.deleteAccount();

      if (!mounted) return;

      // 刪除成功，導航至登入頁面
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帳號已成功刪除')),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '刪除帳號失敗，請稍後再試';

      // 檢查是否是需要重新登入的錯誤
      if (e.toString().contains('requires-recent-login') ||
          e.toString().contains('此操作需要最近登入')) {
        errorMessage = '為了您的帳號安全，請重新登入後再進行刪除操作。';

        // 顯示對話框引導用戶
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('需要重新登入'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await authProvider.signOut();

                  if (!mounted) return;

                   Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                child: const Text('重新登入'),
              ),
            ],
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('刪除帳號'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _prevPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 進度指示器
              LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.error,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildStep1Warning(theme),
                    _buildStep2Reason(theme),
                    _buildStep3Confirmation(theme),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevPage,
                          child: const Text('上一步'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: isLastPage
                            ? (_isConfirmed ? _handleDeleteAccount : null)
                            : _nextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: isLastPage ? theme.colorScheme.error : null,
                          foregroundColor: isLastPage ? theme.colorScheme.onError : null,
                        ),
                        child: Text(isLastPage ? '永久刪除' : '下一步'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep1Warning(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '我們很遺憾看到您離開',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號將永久刪除您的所有資料，包括：\n\n• 個人檔案與照片\n• 所有配對紀錄\n• 聊天訊息\n• 活動報名紀錄\n\n此操作一旦執行將無法復原。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              // 模擬導出資料
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('您的資料導出請求已提交，處理完成後將發送至您的註冊信箱。'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('導出我的資料備份'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Reason(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          '請問您為什麼想要離開？',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '您的回饋將幫助我們改進服務（選填）',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
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
            )),
        if (_selectedReason == '其他')
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              hintText: '請告訴我們更多...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
      ],
    );
  }

  Widget _buildStep3Confirmation(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_forever_rounded,
            size: 80,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  '此操作是不可逆的',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '您將失去所有好友、訊息和活動紀錄。如果您未來想要再次使用 Chingu，您需要重新註冊一個新帳號。',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _isConfirmed,
            onChanged: (value) {
              setState(() {
                _isConfirmed = value ?? false;
              });
            },
            title: const Text('我明白後果，並確認永久刪除我的帳號'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
