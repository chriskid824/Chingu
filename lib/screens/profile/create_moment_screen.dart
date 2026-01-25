import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/moment_model.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入內容或選擇圖片')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) throw Exception('User not logged in');

      String? imageUrl;
      // Generate ID first
      final momentId = FirebaseFirestore.instance.collection('moments').doc().id;

      if (_imageFile != null) {
        final task = _storageService.uploadFile(
          _imageFile!,
          'moments/$momentId.jpg',
        );
        // Wait for upload
        await task;
        imageUrl = await _storageService.getDownloadUrl('moments/$momentId.jpg');
      }

      final moment = MomentModel(
        id: momentId,
        userId: user.uid,
        userName: user.name,
        userAvatar: user.avatarUrl,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createMoment(moment);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發布失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發布動態'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('發布', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '分享你的心情...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _imageFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.image),
      ),
    );
  }
}
