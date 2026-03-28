import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/utils/haptic_utils.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/loading_dialog.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedType = 'suggestion'; // suggestion, bug, other
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    // 收起鍵盤
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId == null) {
        throw Exception('未找到用戶 ID');
      }

      // 如果用戶輸入了 email，使用輸入的，否則使用用戶資料中的 email（如果有的話，這裡暫時只用輸入的）
      final contactEmail = _emailController.text.trim();

      // 顯示加載對話框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingDialog(message: '正在提交...'),
      );

      await _firestoreService.submitFeedback(
        userId: userId,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        contactEmail: contactEmail.isNotEmpty ? contactEmail : null,
      );

      // 關閉加載對話框
      if (mounted) Navigator.pop(context);

      HapticUtils.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('感謝您的反饋！我們會盡快處理。'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // 關閉加載對話框
      if (_isLoading && mounted) Navigator.pop(context);

      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失敗: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('意見反饋'),
        leading: AppIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我們非常重視您的意見',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '請填寫以下表單，告訴我們您的想法或遇到的問題。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // 反饋類型選擇
              Text(
                '反饋類型',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip('suggestion', '建議'),
                  const SizedBox(width: 12),
                  _buildTypeChip('bug', '問題回報'),
                  const SizedBox(width: 12),
                  _buildTypeChip('other', '其他'),
                ],
              ),

              const SizedBox(height: 24),

              // 描述輸入框
              Text(
                '詳細描述',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '請詳細描述您的建議或遇到的問題...',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入描述內容';
                  }
                  if (value.trim().length < 10) {
                    return '描述內容太短，請至少輸入 10 個字';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Email 輸入框 (可選)
              Text(
                '聯絡 Email (可選)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '如果您希望我們回覆，請留下 Email',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return '請輸入有效的 Email 格式';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // 提交按鈕
              GradientButton(
                text: '提交反饋',
                onPressed: _submitFeedback,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>()!;
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
          HapticUtils.selection();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? null
                : theme.cardColor,
            gradient: isSelected ? chinguTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: theme.dividerColor),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chinguTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
