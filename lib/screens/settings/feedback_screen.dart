import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/feedback_model.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  FeedbackType _selectedType = FeedbackType.suggestion;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
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

      String platform;
      try {
        if (Platform.isAndroid) {
          platform = 'Android';
        } else if (Platform.isIOS) {
          platform = 'iOS';
        } else {
          platform = 'Other';
        }
      } catch (e) {
        platform = 'Web/Unknown';
      }

      final feedback = FeedbackModel(
        userId: currentUserId,
        type: FeedbackModel.typeToString(_selectedType),
        content: _contentController.text.trim(),
        contactInfo: _contactController.text.trim().isNotEmpty
            ? _contactController.text.trim()
            : null,
        createdAt: DateTime.now(),
        platform: platform,
        status: 'pending',
      );

      await _firestoreService.submitFeedback(feedback);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('感謝您的回饋！我們會持續改進。'),
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
                '回饋類型',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildRadioOption('功能建議', FeedbackType.suggestion, theme),
              _buildRadioOption('問題回報', FeedbackType.problem, theme),
              _buildRadioOption('其他', FeedbackType.other, theme),

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
                '聯絡方式 (選填)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  hintText: 'Email 或電話，方便我們聯繫您',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),

              SizedBox(height: 32),
              GradientButton(
                text: '提交回饋',
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

  Widget _buildRadioOption(String title, FeedbackType value, ThemeData theme) {
    return RadioListTile<FeedbackType>(
      title: Text(title),
      value: value,
      groupValue: _selectedType,
      onChanged: (FeedbackType? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedType = newValue;
          });
        }
      },
      contentPadding: EdgeInsets.zero,
      activeColor: theme.colorScheme.primary,
    );
  }
}
