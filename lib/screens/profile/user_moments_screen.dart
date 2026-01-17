import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/models.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/widgets/comments_bottom_sheet.dart';

class UserMomentsScreen extends StatelessWidget {
  const UserMomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
        return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Moments'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: MomentService().getMomentsStreamWithLikeStatus(user.uid, targetUserId: user.uid),
        builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
            }
            final moments = snapshot.data ?? [];
            if (moments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Share your first moment!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
            }
            return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: moments.length,
                itemBuilder: (context, index) {
                    final moment = moments[index];
                    return MomentCard(
                        moment: moment,
                        onLikeChanged: (isLiked) {
                             MomentService().toggleLike(moment.id, user.uid, !isLiked);
                        },
                        onCommentTap: () {
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => CommentsBottomSheet(momentId: moment.id),
                            );
                        },
                    );
                },
            );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const CreateMomentSheet(),
            );
        },
        label: const Text('Post'),
        icon: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class CreateMomentSheet extends StatefulWidget {
  const CreateMomentSheet({super.key});

  @override
  State<CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<CreateMomentSheet> {
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submit(String userId, String userName, String? userAvatar) async {
    if (_textController.text.trim().isEmpty && _imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await MomentService().createMoment(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: _textController.text.trim(),
        image: _imageFile,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment shared!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return const SizedBox.shrink();

    return Container(
       padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                  Text('Create Moment', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (_isUploading)
                      const CircularProgressIndicator()
                  else
                      TextButton(
                          onPressed: (_textController.text.isNotEmpty || _imageFile != null)
                              ? () => _submit(user.uid, user.name, user.avatarUrl)
                              : null,
                          child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: InputBorder.none,
              ),
              maxLines: 5,
              onChanged: (val) => setState(() {}),
            ),
            if (_imageFile != null) ...[
                const SizedBox(height: 10),
                Stack(
                    children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => setState(() => _imageFile = null),
                                ),
                            ),
                        ),
                    ],
                ),
            ],
            const SizedBox(height: 10),
            if (_imageFile == null)
              OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Add Photo'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
