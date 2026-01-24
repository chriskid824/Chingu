import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  String _category = 'suggestion';
  final _descriptionController = TextEditingController();
  final _contactInfoController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.uid; // Accessing the getter

      if (uid == null) {
        throw Exception('User not logged in');
      }

      await _firestoreService.submitFeedback(
        userId: uid,
        category: _category,
        description: _descriptionController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isNotEmpty
            ? _contactInfoController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('感謝您的回饋！我們會盡快處理。')),
      );

      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失敗: $e')),
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
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('意見回饋', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我們非常重視您的意見，請告訴我們您的想法或遇到的問題。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Category
              _buildSectionTitle(context, '回饋類型'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                items: const [
                  DropdownMenuItem(value: 'suggestion', child: Text('功能建議')),
                  DropdownMenuItem(value: 'bug', child: Text('錯誤回報')),
                  DropdownMenuItem(value: 'question', child: Text('一般問題')),
                  DropdownMenuItem(value: 'other', child: Text('其他')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Description
              _buildSectionTitle(context, '詳細說明'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '請詳細描述您的建議或遇到的問題...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入說明內容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Contact Info
              _buildSectionTitle(context, '聯絡方式 (選填)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(
                  hintText: 'Email 或電話',
                  prefixIcon: Icon(Icons.contact_mail_outlined, color: theme.colorScheme.secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '提交回饋',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
