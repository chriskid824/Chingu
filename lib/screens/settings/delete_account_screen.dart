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
  bool _requestDataExport = false;
  bool _isAcknowledged = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
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
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.deleteAccount(
        requireDataExport: _requestDataExport,
      );

      if (success && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('帳號已成功刪除')),
        );
      } else if (mounted && authProvider.errorMessage != null) {
        // 顯示通用錯誤訊息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: ${authProvider.errorMessage}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle re-login requirement
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要重新登入'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Logout to let user login again
                  authProvider.signOut().then((_) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  });
                },
                child: const Text('去登入'),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '刪除帳號',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStepIndicator(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildCurrentStepContent(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildBottomButtons(context),
                ),
              ],
            ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(context, 0, '確認'),
          _buildStepLine(context, 0),
          _buildStepDot(context, 1, '備份'),
          _buildStepLine(context, 1),
          _buildStepDot(context, 2, '刪除'),
        ],
      ),
    );
  }

  Widget _buildStepDot(BuildContext context, int stepIndex, String label) {
    final theme = Theme.of(context);
    final isActive = _currentStep >= stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.colorScheme.error : theme.colorScheme.surfaceVariant,
            border: Border.all(
              color: isActive ? theme.colorScheme.error : theme.colorScheme.outline.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
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
            color: isActive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(BuildContext context, int stepIndex) {
    final theme = Theme.of(context);
    final isActive = _currentStep > stepIndex;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        color: isActive ? theme.colorScheme.error : theme.colorScheme.surfaceVariant,
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildWarningStep(context);
      case 1:
        return _buildDataExportStep(context);
      case 2:
        return _buildFinalConfirmationStep(context);
      default:
        return Container();
    }
  }

  Widget _buildWarningStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 24),
        Text(
          '您確定要刪除帳號嗎？',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '此操作無法復原。刪除帳號後：',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _buildWarningItem(context, '您的個人資料、照片和興趣將被永久刪除。'),
        _buildWarningItem(context, '您的所有配對和聊天記錄將消失。'),
        _buildWarningItem(context, '您將無法再登入此帳號。'),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '為什麼想要離開？(選填)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '告訴我們如何改進...',
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _isAcknowledged,
              activeColor: theme.colorScheme.error,
              onChanged: (value) {
                setState(() {
                  _isAcknowledged = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                '我了解此操作是永久性的，且無法復原。',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataExportStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.save_alt_rounded, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          '在離開之前...',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '您是否想要保留一份您的資料副本？',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text('是的，請將資料副本發送至我的電子信箱'),
                subtitle: Text('包含個人資料、活動記錄等 JSON 格式檔案'),
                value: true,
                groupValue: _requestDataExport,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _requestDataExport = value!;
                  });
                },
              ),
              const Divider(),
              RadioListTile<bool>(
                title: const Text('不需要，直接刪除我的資料'),
                value: false,
                groupValue: _requestDataExport,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _requestDataExport = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_requestDataExport)
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: theme.colorScheme.primary.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               children: [
                 Icon(Icons.info_outline, color: theme.colorScheme.primary),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     '資料處理可能需要幾分鐘時間，我們將在準備完成後發送電子郵件給您。',
                     style: theme.textTheme.bodySmall,
                   ),
                 ),
               ],
             ),
          ),
      ],
    );
  }

  Widget _buildFinalConfirmationStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.error.withOpacity(0.1),
          ),
          child: Icon(Icons.delete_forever_rounded, size: 64, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 32),
        Text(
          '最後確認',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '點擊下方按鈕將立即刪除您的帳號。此操作無法撤銷。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentStep == 0) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _isAcknowledged ? _nextStep : null,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('下一步'),
            ),
          ),
        ],
      );
    } else if (_currentStep == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              child: const Text('上一步'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _nextStep,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('下一步'),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _handleDelete,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text('確認刪除我的帳號', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我改變主意了，保留帳號'),
          ),
        ],
      );
    }
  }
}
