import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/moment_provider.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final _textController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入文字或選擇圖片')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    final success = await context.read<MomentProvider>().createMoment(
      userId: user.uid,
      userName: user.name,
      userAvatarUrl: user.avatarUrl,
      content: text,
      imageFile: _selectedImage,
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      final error = context.read<MomentProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '發布失敗')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MomentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('發布動態'),
        actions: [
          if (isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _submit,
              child: const Text('發布', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: '分享你的心情...',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _pickImage,
                ),
                const Text('新增圖片'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
