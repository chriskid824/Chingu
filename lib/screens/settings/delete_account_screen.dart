import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'dart:convert';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 0;
  final TextEditingController _confirmController = TextEditingController();
  bool _isExporting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep += 1;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _handleExportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = await authProvider.exportUserData();

      if (!mounted) return;

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('您的資料'),
          content: SingleChildScrollView(
            child: SelectableText(jsonString),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已複製到剪貼簿')),
                );
              },
              child: const Text('複製'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯出失敗: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_confirmController.text != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入 "DELETE" 以確認刪除')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();

      if (success && mounted) {
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
        String message = '刪除失敗: $e';
        if (e.toString().contains('requires-recent-login') || e.toString().contains('需要最近登入')) {
          message = '為了您的帳號安全，請登出後重新登入，再執行刪除操作。';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('刪除失敗'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('刪除帳號'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            _nextStep();
          } else {
            _handleDeleteAccount();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            _prevStep();
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
           return Padding(
             padding: const EdgeInsets.only(top: 20.0),
             child: Row(
               children: [
                 if (_currentStep == 2)
                   Expanded(
                     child: FilledButton(
                       onPressed: authProvider.isLoading ? null : details.onStepContinue,
                       style: FilledButton.styleFrom(
                         backgroundColor: theme.colorScheme.error,
                         foregroundColor: theme.colorScheme.onError,
                       ),
                       child: authProvider.isLoading
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                         : const Text('確認刪除'),
                     ),
                   )
                 else
                   Expanded(
                     child: FilledButton(
                       onPressed: details.onStepContinue,
                       child: const Text('下一步'),
                     ),
                   ),
                 const SizedBox(width: 12),
                 if (_currentStep > 0)
                   TextButton(
                     onPressed: details.onStepCancel,
                     child: const Text('上一步'),
                   )
                 else
                   TextButton(
                     onPressed: details.onStepCancel,
                     child: const Text('取消'),
                   ),
               ],
             ),
           );
        },
        steps: [
          Step(
            title: const Text('警告'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '刪除帳號是永久性的操作，無法復原。',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('如果您繼續，您將失去：'),
                const SizedBox(height: 8),
                _buildBulletPoint('所有的個人資料和照片'),
                _buildBulletPoint('所有的配對紀錄'),
                _buildBulletPoint('所有的聊天訊息'),
                _buildBulletPoint('所有的活動紀錄'),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('資料匯出（可選）'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('在刪除帳號之前，您可以選擇匯出您的個人資料副本。'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isExporting ? null : _handleExportData,
                  icon: _isExporting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                  label: const Text('匯出我的資料'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('最終確認'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('這是最後一步。請輸入 "DELETE" 確認刪除您的帳號。'),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: '輸入 "DELETE"',
                    border: const OutlineInputBorder(),
                    errorText: _confirmController.text.isNotEmpty && _confirmController.text != 'DELETE' ? '輸入不正確' : null,
                  ),
                  onChanged: (value) {
                    setState(() {}); // 重建以更新按鈕狀態或錯誤提示
                  },
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
