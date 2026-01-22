import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/moment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/moment_service.dart';
import '../../widgets/gradient_button.dart';

class UserMomentsScreen extends StatefulWidget {
  const UserMomentsScreen({super.key});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final MomentService _momentService = MomentService();
  bool _isLoading = false;

  void _showAddMomentDialog(BuildContext context) {
    final contentController = TextEditingController();
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '發布動態',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: '分享你的心情...',
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (selectedImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImage = null;
                                  });
                                },
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
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text('添加照片', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: '發布',
                onPressed: () async {
                  if (contentController.text.trim().isEmpty && selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請輸入內容或選擇照片')),
                    );
                    return;
                  }

                  final user = context.read<AuthProvider>().userModel;
                  if (user == null) return;

                  setState(() => _isLoading = true); // This setState is local to the modal

                  try {
                    final moment = MomentModel(
                      id: '', // Generated by Firestore
                      userId: user.id,
                      userName: user.name,
                      userAvatar: user.avatarUrl,
                      content: contentController.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    await _momentService.createMoment(moment, selectedImage);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('發布成功')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('發布失敗: $e')),
                      );
                    }
                  } finally {
                    // No need to set loading false as dialog closes
                  }
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用戶動態'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('請先登入'))
          : StreamBuilder<List<MomentModel>>(
              stream: _momentService.fetchMoments(user.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('發生錯誤: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final moments = snapshot.data ?? [];

                if (moments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '還沒有動態',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '點擊右下角按鈕發布第一則動態',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moments.length,
                  itemBuilder: (context, index) {
                    final moment = moments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: moment.userAvatar != null
                                      ? CachedNetworkImageProvider(moment.userAvatar!)
                                      : null,
                                  child: moment.userAvatar == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      moment.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('yyyy/MM/dd HH:mm').format(moment.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.delete, color: Colors.red),
                                            title: const Text('刪除', style: TextStyle(color: Colors.red)),
                                            onTap: () {
                                              Navigator.pop(context);
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('刪除動態'),
                                                  content: const Text('確定要刪除這則動態嗎？'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('取消'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        await _momentService.deleteMoment(moment.id);
                                                      },
                                                      child: const Text('刪除', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (moment.content.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(moment.content, style: const TextStyle(fontSize: 15)),
                            ],
                            if (moment.imageUrl != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: moment.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _momentService.likeMoment(moment.id),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite_border, size: 20),
                                      const SizedBox(width: 4),
                                      Text('${moment.likeCount}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Icon(Icons.chat_bubble_outline, size: 20),
                                const SizedBox(width: 4),
                                Text('${moment.commentCount}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMomentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
