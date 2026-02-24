import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/report_block_service.dart';
import 'package:chingu/core/theme/app_theme.dart';

/// 已封鎖用戶管理頁面
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _service = ReportBlockService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final blockedIds = await _service.getBlockedUserIds(userId);

      if (blockedIds.isEmpty) {
        setState(() {
          _blockedUsers = [];
          _isLoading = false;
        });
        return;
      }

      // 獲取被封鎖用戶的資料
      final users = <Map<String, dynamic>>[];
      for (final id in blockedIds) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          users.add({
            'uid': id,
            'name': data['name'] ?? '未知用戶',
            'avatarUrl': data['avatarUrl'],
          });
        }
      }

      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入失敗: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String blockedUserId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除封鎖'),
        content: Text('確定要解除封鎖 $name？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _service.unblockUser(userId, blockedUserId);

      setState(() {
        _blockedUsers.removeWhere((u) => u['uid'] == blockedUserId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已解除封鎖 $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解除封鎖失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: const Text('已封鎖用戶'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? _buildEmptyState(theme, chinguTheme)
              : _buildBlockedList(theme, chinguTheme),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ChinguTheme? chinguTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 80,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '沒有已封鎖的用戶',
            style: TextStyle(
              fontSize: 18,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您封鎖的用戶會顯示在這裡',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedList(ThemeData theme, ChinguTheme? chinguTheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: user['avatarUrl'] != null
                  ? NetworkImage(user['avatarUrl'])
                  : null,
              child: user['avatarUrl'] == null
                  ? Text(
                      user['name'].isNotEmpty
                          ? user['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            title: Text(
              user['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: OutlinedButton(
              onPressed: () => _unblockUser(user['uid'], user['name']),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: theme.colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('解除封鎖'),
            ),
          ),
        );
      },
    );
  }
}
