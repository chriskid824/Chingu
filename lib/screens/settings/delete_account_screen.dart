import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 0;
  String? _selectedReason;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isExporting = false;
  bool _isDeleting = false;

  final List<String> _reasons = [
    '找不到合適的配對',
    '應用程式不穩定',
    '隱私疑慮',
    '收到太多通知',
    '已找到伴侶',
    '其他原因',
  ];

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _handleDataExport() async {
    setState(() {
      _isExporting = true;
    });

    // 模擬數據導出過程
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('數據導出請求已提交，我們將在準備好後發送至您的電子郵件信箱。'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await context.read<AuthProvider>().deleteAccount();

      if (mounted) {
        // 導航至登入頁面並清除路由堆疊
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
        final errorMessage = e.toString().replaceAll('Exception: ', '');

        // 檢查是否需要重新登入
        if (errorMessage.contains('需要最近登入') || errorMessage.contains('requires-recent-login')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('需要重新驗證'),
              content: const Text('為了安全起見，刪除帳號需要您最近有登入紀錄。請登出後重新登入，然後再次嘗試刪除帳號。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    // 執行登出並跳轉到登入頁
                    context.read<AuthProvider>().signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  child: const Text('前往登入'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('刪除帳號', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
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
          // 進度指示器
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),
          Expanded(
            child: _buildCurrentStep(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildExportDataStep(theme);
      case 1:
        return _buildReasonStep(theme);
      case 2:
        return _buildConfirmationStep(theme);
      default:
        return Container();
    }
  }

  Widget _buildExportDataStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.download_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '離開之前...',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號將永久移除您的所有資料，包括個人檔案、配對紀錄和聊天訊息。此操作無法復原。',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          Text(
            '如果您想保留資料備份，請先導出您的數據。',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _isExporting ? null : _handleDataExport,
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(_isExporting ? '準備中...' : '導出我的數據'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextStep,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonStep(ThemeData theme) {
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
            '您的回饋能幫助我們改進。',
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
            activeColor: theme.colorScheme.primary,
          )),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '告訴我們更多細節（選填）...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedReason != null ? _nextStep : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續'),
            ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_rounded, size: 64, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 32),
          Text(
            '確定要刪除帳號嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '請注意：此操作將永久刪除您的帳號及所有相關資料。如果您日後想重新使用，需要重新註冊。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isDeleting ? null : _handleDeleteAccount,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('確認刪除帳號'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('我再考慮一下'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
