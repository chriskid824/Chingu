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
  bool _exportCompleted = false;
  final TextEditingController _confirmationController = TextEditingController();

  final List<String> _reasons = [
    '覺得找不到合適的對象',
    '遇到騷擾或不愉快的體驗',
    '隱私考量',
    '已經找到伴侶',
    '其他原因',
  ];

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    // Simulate export delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isExporting = false;
        _exportCompleted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('資料匯出成功，已發送至您的信箱')),
      );
    }
  }

  void _handleDelete() {
    // Implement actual delete logic here
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: Navigate to login or splash screen after deletion
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
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(0, '原因', theme, chinguTheme),
                _buildStepConnector(0, theme),
                _buildStepIndicator(1, '備份', theme, chinguTheme),
                _buildStepConnector(1, theme),
                _buildStepIndicator(2, '確認', theme, chinguTheme),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStepContent(theme),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBottomButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, ThemeData theme, ChinguTheme? chinguTheme) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
              border: isCurrent
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step, ThemeData theme) {
    final isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildReasonStep(theme);
      case 1:
        return _buildExportStep(theme);
      case 2:
        return _buildConfirmationStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReasonStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '為什麼想要離開？',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '我們很遺憾看到您離開。請告訴我們原因，幫助我們改進服務。',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
          '備份您的資料',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '在刪除帳號之前，您可能想要備份您的對話記錄、照片和個人資料。刪除後這些資料將無法復原。',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.surfaceVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.download, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('個人資料封存檔', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('包含對話記錄、相片與個人設定', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isExporting)
                Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text('正在準備您的檔案...', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                )
              else if (_exportCompleted)
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('匯出完成', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                )
              else
                OutlinedButton(
                  onPressed: _handleExport,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    foregroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('請求匯出資料'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: null, // Read-only checked to signify understanding, or we can use it to let them confirm they don't want to export
              fillColor: MaterialStateProperty.all(theme.colorScheme.surfaceVariant),
              checkColor: theme.colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                '我了解刪除帳號後資料將無法復原',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最終確認',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 8),
        Text(
          '這項操作是永久性的，無法復原。請在下方輸入 "DELETE" 以確認刪除您的帳號。',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _confirmationController,
          decoration: InputDecoration(
            hintText: 'DELETE',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '刪除後，您將無法登入、存取配對記錄或查看過往訊息。',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    if (_currentStep == 2) {
      final isConfirmed = _confirmationController.text == 'DELETE';
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isConfirmed ? _handleDelete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.3),
          ),
          child: const Text('確認永久刪除'),
        ),
      );
    }

    return GradientButton(
      text: '下一步',
      onPressed: _canProceed() ? () {
        setState(() {
          _currentStep++;
        });
      } : null,
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedReason != null;
    }
    if (_currentStep == 1) {
      return true; // Can skip export
    }
    return false;
  }
}
