import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 0;
  String _selectedReason = '';
  final TextEditingController _otherReasonController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isExportRequested = false;

  final List<String> _reasons = [
    '找不到感興趣的對象',
    '應用程式出錯太頻繁',
    '我想暫時休息一下',
    '我已經找到對象了',
    '隱私考量',
    '其他',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('刪除帳號', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          // 進度指示器
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),
          Expanded(
            child: _buildStepContent(context, theme, chinguTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildWarningStep(context, theme);
      case 1:
        return _buildReasonStep(context, theme);
      case 2:
        return _buildExportStep(context, theme);
      case 3:
        return _buildConfirmStep(context, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // 步驟 1: 警告
  Widget _buildWarningStep(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            '我們很遺憾看到您要離開',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號將會導致以下結果：',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildWarningItem(theme, '您的個人資料將被永久刪除'),
          _buildWarningItem(theme, '您的所有配對和聊天記錄將消失'),
          _buildWarningItem(theme, '您將無法復原此操作'),
          const Spacer(),
          GradientButton(
            text: '繼續',
            onPressed: _nextStep,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error,
                theme.colorScheme.error.withOpacity(0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: theme.colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 步驟 2: 原因
  Widget _buildReasonStep(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想刪除帳號？',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您的反饋對我們改進服務非常重要',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          ..._reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.error,
              )),
          if (_selectedReason == '其他')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  hintText: '請告訴我們更多...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: '繼續',
              onPressed: _selectedReason.isNotEmpty ? _nextStep : null,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.error,
                  theme.colorScheme.error.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 步驟 3: 導出數據
  Widget _buildExportStep(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.save_alt_rounded,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '在離開之前備份您的數據',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '您可以請求導出您的個人數據。我們會將數據打包並發送到您的電子郵件信箱。',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (_isExportRequested)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '已收到您的請求。數據準備好後將發送至您的信箱。',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await context.read<AuthProvider>().requestDataExport();
                  setState(() {
                    _isExportRequested = true;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('請求失敗: $e')),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('請求數據導出'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const Spacer(),
          GradientButton(
            text: '繼續刪除',
            onPressed: _nextStep,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error,
                theme.colorScheme.error.withOpacity(0.8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 步驟 4: 確認
  Widget _buildConfirmStep(BuildContext context, ThemeData theme) {
    final authProvider = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '為了安全起見，請輸入您的密碼以確認刪除帳號。此操作無法撤銷。',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: '密碼',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: authProvider.errorMessage,
            ),
          ),
          const SizedBox(height: 48),
          if (authProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _passwordController.text.isNotEmpty
                    ? () async {
                        final password = _passwordController.text;
                        final success = await _showFinalConfirmationDialog(context);
                        if (success == true) {
                          if (!context.mounted) return;
                          try {
                            await context.read<AuthProvider>().deleteAccount(password);
                            if (!context.mounted) return;
                            // 導航到 Splash 或 Login 畫面，並清除路由堆疊
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('帳號已成功刪除')),
                            );
                          } catch (e) {
                            // 錯誤已在 Provider 中處理並設置 errorMessage
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '永久刪除我的帳號',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showFinalConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確定要刪除嗎？'),
        content: const Text('您的帳號將被永久刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );
  }
}
