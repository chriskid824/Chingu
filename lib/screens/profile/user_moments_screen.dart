import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/moment_card.dart';

class UserMomentsScreen extends StatefulWidget {
  final String? userId;

  const UserMomentsScreen({super.key, this.userId});

  @override
  State<UserMomentsScreen> createState() => _UserMomentsScreenState();
}

class _UserMomentsScreenState extends State<UserMomentsScreen> {
  late Future<List<MomentModel>> _momentsFuture;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  void _loadMoments() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetUserId = widget.userId ?? authProvider.userModel?.uid;

    if (targetUserId != null) {
      setState(() {
        _momentsFuture = _firestoreService.getUserMoments(targetUserId);
      });
    } else {
        // Should not happen if logged in
         setState(() {
            _momentsFuture = Future.value([]);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel?.uid;
    final isCurrentUser = widget.userId == null || widget.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('動態'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<MomentModel>>(
        future: _momentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
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
                    '尚無動態',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: moments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final moment = moments[index];
              return MomentCard(
                moment: moment,
                onDelete: isCurrentUser ? () => _deleteMoment(moment.id) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, AppRoutes.createMoment);
                if (result == true) {
                  _loadMoments();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _deleteMoment(String momentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除動態'),
        content: const Text('確定要刪除這則動態嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteMoment(momentId);
        _loadMoments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動態已刪除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('刪除失敗: $e')),
          );
        }
      }
    }
  }
}
