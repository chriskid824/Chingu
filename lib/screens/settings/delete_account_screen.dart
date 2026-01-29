import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Survey State
  String? _selectedReason;
  final List<String> _reasons = [
    '找到伴侶了',
    '應用程式不好用',
    '遇到太多 Bug',
    '隱私考量',
    '其他原因',
  ];

  // Export State
  bool _requestExport = false;

  // Confirmation State
  final TextEditingController _confirmController = TextEditingController();
  final String _confirmKeyword = 'DELETE';

  @override
  void dispose() {
    _pageController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    // 模擬資料導出請求
    if (_requestExport) {
      await Future.delayed(const Duration(seconds: 1)); // 模擬API調用
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已收到您的資料導出請求，將發送至您的電子郵件')),
        );
      }
    }

    final success = await authProvider.deleteAccount();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 導航回登入頁面並清除路由堆疊
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '刪除帳號失敗，請稍後再試'),
          backgroundColor: Colors.red,
        ),
      );
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
          onPressed: _previousPage,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: (_currentPage + 1) / 4,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // 禁止手勢滑動
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWarningStep(theme),
                    _buildSurveyStep(theme),
                    _buildExportStep(theme),
                    _buildConfirmationStep(theme),
                  ],
                ),
              ),
              _buildBottomBar(theme),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '您確定要刪除帳號嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '此操作無法復原。刪除帳號後：\n\n'
            '• 您的個人資料將被永久刪除\n'
            '• 所有的配對記錄和聊天記錄將消失\n'
            '• 您無法恢復之前的活動記錄',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '我們很遺憾看到您離開',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('請問您刪除帳號的主要原因是？', style: theme.textTheme.bodyMedium),
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
        ],
      ),
    );
  }

  Widget _buildExportStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_download_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '保留您的回憶？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，您可以選擇導出您的個人資料副本。我們將在準備好後發送至您的電子郵件。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CheckboxListTile(
            title: const Text('請求導出我的資料'),
            value: _requestExport,
            onChanged: (value) {
              setState(() {
                _requestExport = value ?? false;
              });
            },
            secondary: const Icon(Icons.file_copy_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 24),
          Text(
            '為了確認這是您的操作，請在下方輸入 "$_confirmKeyword"',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: _confirmKeyword,
              border: const OutlineInputBorder(),
              errorText: _confirmController.text.isNotEmpty && _confirmController.text != _confirmKeyword
                  ? '輸入不正確'
                  : null,
            ),
            textAlign: TextAlign.center,
            onChanged: (value) {
              setState(() {}); // 重建以更新按鈕狀態
            },
          ),
          const SizedBox(height: 32),
          if (_confirmController.text == _confirmKeyword)
            Text(
              '再見了！希望未來能再次為您服務。',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isLastPage = _currentPage == 3;
    final canProceed = _currentPage != 1 || _selectedReason != null; // Survey step requires selection? Optional for now.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: const Text('上一步'),
            )
          else
            const SizedBox(width: 64), // Placeholder for alignment

          if (isLastPage)
            FilledButton(
              onPressed: _confirmController.text == _confirmKeyword ? _handleDelete : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('確認刪除'),
            )
          else
            FilledButton(
              onPressed: canProceed ? _nextPage : null,
              child: const Text('下一步'),
            ),
        ],
      ),
    );
  }
}
