import 'package:flutter/material.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/services/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 2: Reason
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  final List<String> _reasons = [
    '找不到感興趣的對象',
    '遇到技術問題',
    '隱私考量',
    '想休息一陣子',
    '已找到伴侶',
    '其他',
  ];

  // Step 3: Confirmation
  bool _isConfirmed = false;
  final TextEditingController _confirmationTextController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _otherReasonController.dispose();
    _confirmationTextController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _handleExportData() async {
    // 模擬數據導出請求
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('數據導出請求已收到，我們將在準備完成後發送至您的信箱')),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    setState(() => _isLoading = true);
    try {
      await _authService.deleteAccount();
      if (mounted) {
        // 刪除成功，導航至登入頁面
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
        String errorMessage = e.toString();
        if (errorMessage.contains('requires-recent-login')) {
          _showReLoginDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage.replaceAll('Exception: ', ''))),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要重新登入'),
        content: const Text('為了安全起見，刪除帳號前需要重新驗證您的身分。請重新登入後再試。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('去登入'),
          ),
        ],
      ),
    );
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
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _currentStep == 2 ? theme.colorScheme.error : theme.colorScheme.primary
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '您確定要刪除帳號嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號是永久性的操作。您的個人資料、配對紀錄、聊天訊息都將被永久刪除，無法復原。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '保留您的回憶',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('在刪除帳號之前，您可以選擇導出您的個人數據副本。'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleExportData,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('請求數據導出'),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextStep,
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想要離開？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '您的回饋對我們很重要，可以幫助我們改進服務。',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
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
                    controller: _otherReasonController,
                    decoration: const InputDecoration(
                      hintText: '請告訴我們更多...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: _previousStep,
                child: const Text('上一步'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _nextStep,
                child: const Text('繼續'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text('為了確認這是您本人的操作，並且您了解此操作的後果，請勾選以下選項：'),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _isConfirmed,
            onChanged: (value) {
              setState(() {
                _isConfirmed = value ?? false;
              });
            },
            title: const Text('我了解刪除帳號後，所有資料將無法復原。'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: theme.colorScheme.error,
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _isConfirmed ? _handleDeleteAccount : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('確認永久刪除帳號'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消並返回設定'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
