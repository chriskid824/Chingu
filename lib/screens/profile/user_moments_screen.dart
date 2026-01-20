import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/core/routes/app_router.dart';

class UserMomentsScreen extends StatefulWidget {
  const UserMomentsScreen({super.key});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  final MomentService _momentService = MomentService();
  List<MomentModel> _moments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) {
        setState(() {
            _isLoading = false;
            _errorMessage = 'User not found';
        });
        return;
      }

      final moments = await _momentService.getMoments(userId: user.uid);
      if (mounted) {
        setState(() {
          _moments = moments;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '載入失敗: $e';
        });
      }
    }
  }

  Future<void> _deleteMoment(String momentId) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('刪除動態'),
              content: const Text('確定要刪除這則動態嗎？'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('刪除', style: TextStyle(color: Colors.red))),
              ],
          ),
      );

      if (confirm == true) {
          try {
              await _momentService.deleteMoment(momentId);
              _loadMoments(); // Refresh list
          } catch(e) {
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
              }
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的動態'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.createMoment);
          if (result == true) {
            _loadMoments();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _loadMoments,
                  child: _moments.isEmpty
                      ? const Center(child: Text('還沒有任何動態，快來分享吧！'))
                      : ListView.builder(
                          itemCount: _moments.length,
                          itemBuilder: (context, index) {
                            final moment = _moments[index];
                            return _buildMomentCard(moment);
                          },
                        ),
                ),
    );
  }

  Widget _buildMomentCard(MomentModel moment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: moment.userAvatar != null
                  ? CachedNetworkImageProvider(moment.userAvatar!)
                  : null,
              child: moment.userAvatar == null ? const Icon(Icons.person) : null,
            ),
            title: Text(moment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(moment.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
                onSelected: (value) {
                    if (value == 'delete') {
                        _deleteMoment(moment.id);
                    }
                },
                itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('刪除')),
                ],
            ),
          ),
          if (moment.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(moment.content),
            ),
          if (moment.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CachedNetworkImage(
                imageUrl: moment.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          // Actions bar (Like, Comment - placeholders)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    moment.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: moment.isLiked ? Colors.red : null,
                  ),
                  onPressed: () {
                    // Implement like functionality
                  },
                ),
                Text('${moment.likeCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // Implement comment functionality
                  },
                ),
                Text('${moment.commentCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
