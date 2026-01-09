import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 0;
  String? _selectedReason;
  bool _isExporting = false;
  bool _confirmed = false;

  final List<String> _reasons = [
    '找到對象了',
    '遇到技術問題',
    '暫時休息一下',
    '隱私考量',
    '其他原因',
  ];

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
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(theme, chinguTheme),
              const SizedBox(height: 32),
              Expanded(
                child: _buildCurrentStep(theme),
              ),
              _buildBottomButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, ChinguTheme? chinguTheme) {
    return Row(
      children: [
        _buildStepDot(0, theme, chinguTheme),
        _buildStepLine(0, theme),
        _buildStepDot(1, theme, chinguTheme),
        _buildStepLine(1, theme),
        _buildStepDot(2, theme, chinguTheme),
      ],
    );
  }

  Widget _buildStepDot(int step, ThemeData theme, ChinguTheme? chinguTheme) {
    final isActive = _currentStep >= step;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
        gradient: isActive ? chinguTheme?.primaryGradient : null,
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(int step, ThemeData theme) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildReasonStep(theme);
      case 1:
        return _buildExportStep(theme);
      case 2:
        return _buildConfirmationStep(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildReasonStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '為什麼想離開？',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '您的回饋將幫助我們改進服務',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        ..._reasons.map((reason) => RadioListTile<String>(
          title: Text(reason),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) => setState(() => _selectedReason = value),
          activeColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildExportStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '保留您的回憶',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '在刪除帳號之前，您可以選擇導出您的個人資料和聊天記錄。',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('個人資料'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('聊天記錄'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('配對歷史'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isExporting ? null : _simulateExport,
            icon: _isExporting
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download),
            label: Text(_isExporting ? '準備中...' : '下載資料副本'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _simulateExport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料導出請求已提交，將發送至您的電子郵件')),
      );
    }
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    return Column(
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '此操作無法復原',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '您的所有資料，包括配對、訊息和個人資訊將被永久刪除。',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (value) => setState(() => _confirmed = value ?? false),
          title: const Text('我了解並同意永久刪除我的帳號'),
          activeColor: theme.colorScheme.error,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Column(
      children: [
        if (_currentStep < 2)
          GradientButton(
            text: '下一步',
            onPressed: _canProceed() ? () => setState(() => _currentStep++) : null,
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmed ? _deleteAccount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text(
                '確認刪除帳號',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (_currentStep < 2)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
      ],
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) return _selectedReason != null;
    return true;
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('處理中'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            const Text('正在刪除您的帳號...'),
          ],
        ),
      ),
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss dialog
        // Navigate to login or splash
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }
}
