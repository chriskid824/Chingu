import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/feedback_model.dart';
import '../../services/feedback_service.dart';
import '../../providers/auth_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final FeedbackService? feedbackService;
  const FeedbackScreen({super.key, this.feedbackService});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  FeedbackType _selectedType = FeedbackType.suggestion;
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  late final FeedbackService _feedbackService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();

    // Pre-fill email from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) throw Exception('User not logged in');

      // Generate a simple ID
      final String feedbackId = DateTime.now().millisecondsSinceEpoch.toString();

      final feedback = FeedbackModel(
        id: feedbackId,
        userId: user.uid,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        contactEmail: _emailController.text.trim(),
        createdAt: DateTime.now(),
        platform: Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown'),
      );

      List<File> files = _selectedImages.map((x) => File(x.path)).toList();

      await _feedbackService.submitFeedback(feedback, files);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('感謝您的回饋'),
          content: const Text('我們已收到您的意見，將會盡快處理。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back
              },
              child: const Text('確定'),
            ),
          ],
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('意見回饋'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您的意見對我們很重要',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '請填寫下表，告訴我們您的建議或遇到的問題。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Type Dropdown
              DropdownButtonFormField<FeedbackType>(
                key: const Key('feedback_type_dropdown'),
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '回饋類型',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: FeedbackType.values.map((type) {
                  String label;
                  switch (type) {
                    case FeedbackType.suggestion:
                      label = '功能建議';
                      break;
                    case FeedbackType.bug:
                      label = '問題回報';
                      break;
                    case FeedbackType.other:
                      label = '其他';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                key: const Key('feedback_description_field'),
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '詳細說明',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: '請詳細描述您的建議或遇到的問題...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入說明內容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                key: const Key('feedback_email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '聯絡 Email',
                  border: OutlineInputBorder(),
                  hintText: '以便我們進一步與您聯繫',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入 Email';
                  }
                  if (!value.contains('@')) {
                    return '請輸入有效的 Email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Image Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('附件圖片 (可選)', style: theme.textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('新增圖片'),
                  ),
                ],
              ),
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  key: const Key('feedback_submit_button'),
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('提交回饋'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
