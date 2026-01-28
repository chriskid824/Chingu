import 'package:flutter/material.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/feedback_service.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackService = FeedbackService();
  final _authService = AuthService();

  String _type = 'suggestion';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      final userId = user?.uid ?? 'anonymous';

      final feedback = FeedbackModel(
        userId: userId,
        type: _type,
        content: _contentController.text.trim(),
        contactEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        createdAt: DateTime.now(),
        platform: Theme.of(context).platform.toString(),
      );

      await _feedbackService.submitFeedback(feedback);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('感謝您的回饋！我們將盡快處理。')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失敗: $e'), backgroundColor: Colors.red),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('意見回饋'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您的意見對我們很重要',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '無論是功能建議、問題回報，或是單純想聊聊，都歡迎告訴我們。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Feedback Type Dropdown
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: '回饋類型',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(value: 'suggestion', child: Text('功能建議')),
                  DropdownMenuItem(value: 'bug', child: Text('問題回報')),
                  DropdownMenuItem(value: 'other', child: Text('其他')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Content TextField
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: '回饋內容',
                  alignLabelWithHint: true,
                  hintText: '請詳細描述您的建議或遇到的問題...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入內容';
                  }
                  if (value.trim().length < 10) {
                    return '內容至少需要10個字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Email TextField
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '聯絡信箱 (選填)',
                  hintText: '若是問題回報，建議留下信箱以便聯繫',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return '請輸入有效的電子郵件';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '提交回饋',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
