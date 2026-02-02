import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedType = 'suggestion';
  bool _isSubmitting = false;

  final Map<String, String> _feedbackTypes = {
    'suggestion': '功能建議',
    'bug_report': '問題回報',
    'other': '其他',
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill email if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.firebaseUser?.email != null) {
      _emailController.text = authProvider.firebaseUser!.email!;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.uid;

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _firestoreService.submitFeedback(
        userId: currentUserId,
        type: _selectedType,
        content: _contentController.text.trim(),
        contactEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('感謝您的反饋，我們會持續改進！'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交失敗，請稍後再試'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('意見回饋'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您的意見是我們進步的動力',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '反饋類型',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ..._feedbackTypes.entries.map((entry) => RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              )),
              SizedBox(height: 24),
              Text(
                '內容描述',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入內容';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '請詳細描述您的建議或遇到的問題...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
              SizedBox(height: 24),
              Text(
                '聯絡信箱 (選填)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '如果您希望收到回覆，請留下 Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
              SizedBox(height: 32),
              GradientButton(
                text: _isSubmitting ? '提交中...' : '提交反饋',
                isLoading: _isSubmitting,
                onPressed: () {
                  _submitFeedback();
                },
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
