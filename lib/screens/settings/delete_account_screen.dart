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
  final TextEditingController _confirmController = TextEditingController();
  bool _isExportRequested = false;
  bool _isExporting = false;

  final List<String> _reasons = [
    '找到對象了',
    '不喜歡這個應用程式',
    '遇到技術問題',
    '隱私考量',
    '其他原因',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _confirmController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('刪除帳號 (${_currentPage + 1}/4)'),
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
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
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
                _buildWarningStep(context),
                _buildExportStep(context),
                _buildReasonStep(context),
                _buildConfirmStep(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Warning
  Widget _buildWarningStep(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '您確定要離開嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號將會永久移除以下資料，且無法恢復：',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildWarningItem(context, Icons.person_off, '您的個人資料和照片'),
          _buildWarningItem(context, Icons.favorite_border, '所有的配對紀錄'),
          _buildWarningItem(context, Icons.chat_bubble_outline, '所有的聊天訊息'),
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
        ],
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Step 2: Data Export
  Widget _buildExportStep(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '在您離開之前...',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '您可以選擇導出您的個人資料副本。我們會將下載連結發送到您的電子信箱。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (!_isExportRequested)
            OutlinedButton.icon(
              icon: _isExporting
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? '處理中...' : '請求資料導出'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _isExporting
                  ? null
                  : () async {
                      setState(() {
                        _isExporting = true;
                      });
                      final success = await authProvider.requestDataExport();
                      if (mounted) {
                        setState(() {
                          _isExporting = false;
                          if (success) {
                            _isExportRequested = true;
                          }
                        });
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('導出請求已發送，請檢查您的信箱')),
                          );
                        }
                      }
                    },
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('導出請求已發送', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續下一步'),
            ),
          ),
          TextButton(
            onPressed: _nextPage,
            child: const Text('不需要導出，直接繼續'),
          ),
        ],
      ),
    );
  }

  // Step 3: Reason
  Widget _buildReasonStep(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想要刪除帳號？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('您的回饋能幫助我們做得更好 (選填)'),
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
          )).toList(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續下一步'),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Confirm
  Widget _buildConfirmStep(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDeleteEnabled = _confirmController.text.toUpperCase() == 'DELETE' ||
                           _confirmController.text == '刪除';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              '最終確認',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            const Text(
              '此操作無法復原。您的帳號將會被永久刪除。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: '請輸入 "DELETE" 或 "刪除" 以確認',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to update button state
              },
            ),
            const SizedBox(height: 32),
            if (authProvider.isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isDeleteEnabled
                      ? () async {
                          final success = await authProvider.deleteAccount();
                          if (success && mounted) {
                            // Navigate to login/splash and remove all routes
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          } else if (authProvider.errorMessage != null && mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authProvider.errorMessage!)),
                            );
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('永久刪除帳號'),
                ),
              ),
            const SizedBox(height: 16),
            if (!authProvider.isLoading)
              TextButton(
                onPressed: () {
                   Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
          ],
        ),
      ),
    );
  }
}
