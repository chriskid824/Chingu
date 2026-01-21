import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
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
  String? _selectedReason;
  bool _isConfirmed = false;
  bool _isLoading = false;

  final List<String> _reasons = [
    '找不到合適的配對',
    '應用程式不穩定',
    '隱私考量',
    '已經找到伴侶',
    '暫時休息',
    '其他',
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleExportData() async {
    // 模擬數據導出請求
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('導出數據請求已收到'),
        content: const Text(
          '我們已收到您的數據導出請求。系統將在 48 小時內整理您的數據並發送下載連結至您的註冊信箱。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    if (!_isConfirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.deleteAccount();

      if (mounted) {
        // 刪除成功，導向登入頁面
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 顯示錯誤訊息
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('無法刪除帳號'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 如果是需要重新登入的錯誤，可以引導用戶去登出
                  if (e.toString().contains('需要最近登入')) {
                     Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                child: const Text('確定'),
              ),
            ],
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
          onPressed: _previousStep,
        ),
      ),
      body: Column(
        children: [
          // 進度條
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _currentStep == 2 ? theme.colorScheme.error : theme.colorScheme.primary,
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
            '此操作無法復原',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號將永久移除您的：',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(theme, '個人資料與照片'),
          _buildBulletPoint(theme, '所有配對紀錄'),
          _buildBulletPoint(theme, '聊天訊息'),
          _buildBulletPoint(theme, '活動報名紀錄'),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            '在您離開之前...',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '如果您只是想暫時休息，可以考慮關閉通知或登出應用程式。如果您需要備份資料，請點擊下方按鈕。',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _handleExportData,
            icon: const Icon(Icons.download),
            label: const Text('導出我的數據'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('繼續刪除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想離開？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '您的回饋能幫助我們改進服務（選填）',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('下一步'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextStep,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('略過'),
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '刪除帳號後，您將無法登入或取回任何資料。',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
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
            title: const Text('我了解此操作是永久性的，且無法復原。'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const Spacer(),
          FilledButton(
            onPressed: (_isConfirmed && !_isLoading) ? _handleDeleteAccount : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('永久刪除帳號'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
