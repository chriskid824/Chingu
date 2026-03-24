import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/storage_service.dart';
import 'package:chingu/screens/profile/profile_setup_screen.dart' show industryList;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  String? _selectedGender;
  String? _selectedIndustry;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
    _ageController = TextEditingController(text: user?.age.toString() ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _selectedGender = user?.gender;
    // 嘗試匹配產業別（舊資料可能是自由輸入的職業名稱）
    _selectedIndustry = industryList.contains(user?.job) ? user?.job : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.uid;

      if (uid == null) {
        throw Exception('User not logged in');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'user_avatars/${uid}_$timestamp.jpg';
      final file = File(image.path);

      final task = _storageService.uploadFile(file, path);

      task.snapshotEvents.listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await task;

      final downloadUrl = await _storageService.getDownloadUrl(path);

      await authProvider.updateUserData({'avatarUrl': downloadUrl});

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('頭像更新成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _selectedGender ?? 'male',
    };

    if (_selectedIndustry != null) {
      data['job'] = _selectedIndustry;
    }

    final bio = _bioController.text.trim();
    if (bio.isNotEmpty) {
      data['bio'] = bio;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserData(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('個人資料已更新 ✅'),
          backgroundColor: Theme.of(context).extension<ChinguTheme>()?.success ?? Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('更新失敗，請稍後再試'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showIndustryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IndustryPickerSheet(
        selected: _selectedIndustry,
        onSelected: (industry) {
          setState(() => _selectedIndustry = industry);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('編輯個人資料',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 頭像 =====
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.userModel;
                  return Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: chinguTheme?.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _isUploading
                                ? Container(
                                    color: Colors.black45,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: _uploadProgress,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                        Text(
                                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : (user?.avatarUrl != null
                                    ? Image.network(
                                        user!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                                      )
                                    : const Icon(Icons.person_rounded, size: 60, color: Colors.white)),
                          ),
                        ),
                        if (!_isUploading)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: chinguTheme?.success ?? Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isUploading ? '正在上傳...' : '點擊相機圖標更換照片',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ===== 基本資料 =====
              _buildSectionTitle(context, '📝 基本資料', theme.colorScheme.primary),
              const SizedBox(height: 16),

              // 姓名
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(theme, '姓名', Icons.person_outline, theme.colorScheme.primary),
                validator: (v) => (v == null || v.trim().isEmpty) ? '請輸入姓名' : null,
              ),
              const SizedBox(height: 16),

              // 年齡 + 性別
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(theme, '年齡', Icons.cake_outlined, theme.colorScheme.secondary),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '必填';
                        final age = int.tryParse(v);
                        if (age == null || age < 18 || age > 100) return '18-100';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _inputDecoration(theme, '性別', Icons.people_outline, theme.colorScheme.primary),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('男性')),
                        DropdownMenuItem(value: 'female', child: Text('女性')),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ===== 產業別 =====
              _buildSectionTitle(context, '💼 產業別', theme.colorScheme.secondary),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showIndustryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedIndustry != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: _selectedIndustry != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedIndustry ?? '選擇產業別',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedIndustry != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== 關於我 =====
              _buildSectionTitle(context, '✨ 關於我', theme.colorScheme.primary),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: '分享一些關於你的事情...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              // ===== 儲存按鈕 =====
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      _isSaving ? '儲存中...' : '儲存變更',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String label, IconData icon, Color iconColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: iconColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.cardColor,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─── 產業別搜尋器（複用 onboarding 的邏輯） ───
class _IndustryPickerSheet extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _IndustryPickerSheet({required this.selected, required this.onSelected});

  @override
  State<_IndustryPickerSheet> createState() => _IndustryPickerSheetState();
}

class _IndustryPickerSheetState extends State<_IndustryPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = industryList;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? industryList
          : industryList.where((i) => i.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('選擇產業別',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜尋產業...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final industry = _filtered[index];
                final isSelected = industry == widget.selected;
                return ListTile(
                  onTap: () => widget.onSelected(industry),
                  title: Text(industry,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    )),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
