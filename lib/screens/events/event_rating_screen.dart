import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class EventRatingScreen extends StatefulWidget {
  final String eventId;
  final UserModel targetUser;

  const EventRatingScreen({
    super.key,
    required this.eventId,
    required this.targetUser,
  });

  @override
  State<EventRatingScreen> createState() => _EventRatingScreenState();
}

class _EventRatingScreenState extends State<EventRatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _availableTags = [
    {'label': '有趣', 'icon': Icons.mood_rounded, 'color': Colors.blue},
    {'label': '健談', 'icon': Icons.chat_rounded, 'color': Colors.purple},
    {'label': '準時', 'icon': Icons.schedule_rounded, 'color': Colors.green},
    {'label': '有禮貌', 'icon': Icons.sentiment_satisfied_rounded, 'color': Colors.amber},
    {'label': '話題豐富', 'icon': Icons.lightbulb_rounded, 'color': Colors.red},
    {'label': '氣氛愉快', 'icon': Icons.celebration_rounded, 'color': Colors.lightBlue},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇評分星數')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser == null) throw Exception('用戶未登入');

      await FirestoreService().submitRating(
        raterId: currentUser.uid,
        targetId: widget.targetUser.uid,
        eventId: widget.eventId,
        rating: _rating.toDouble(),
        comment: _commentController.text,
        tags: _selectedTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('評價已提交')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失敗: $e')),
        );
      }
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
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: chinguTheme?.warning ?? Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text('評價夥伴', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '給 ${widget.targetUser.name} 的評價',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: widget.targetUser.avatarUrl != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: CachedNetworkImageProvider(
                        widget.targetUser.avatarUrl!,
                        cacheManager: ImageCacheManager().manager,
                      ),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text('整體評分', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: chinguTheme?.warning ?? Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),
            Text('您的感想', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '分享您的互動體驗...',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('快速標籤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag['label']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag['label']);
                      } else {
                        _selectedTags.add(tag['label']);
                      }
                    });
                  },
                  child: _buildTagChip(
                    tag['label'],
                    tag['icon'],
                    tag['color'],
                    isSelected,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('提交評價', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTagChip(String label, IconData icon, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : color.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
