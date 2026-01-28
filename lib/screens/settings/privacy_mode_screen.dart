import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';

class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({super.key});

  @override
  State<PrivacyModeScreen> createState() => _PrivacyModeScreenState();
}

class _PrivacyModeScreenState extends State<PrivacyModeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  bool _isOnlineStatusHidden = false;
  bool _isLastSeenHidden = false;

  // We keep a reference but mainly use the local bools for UI state
  // ignore: unused_field
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await _firestoreService.getUser(uid);
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _isOnlineStatusHidden = user.isOnlineStatusHidden;
          _isLastSeenHidden = user.isLastSeenHidden;
          _isLoading = false;
        });
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入設定失敗: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(String field, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Optimistic update
    setState(() {
      if (field == 'isOnlineStatusHidden') {
        _isOnlineStatusHidden = value;
      } else if (field == 'isLastSeenHidden') {
        _isLastSeenHidden = value;
      }
    });

    try {
      await _firestoreService.updateUser(uid, {field: value});
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          if (field == 'isOnlineStatusHidden') {
            _isOnlineStatusHidden = !value;
          } else if (field == 'isLastSeenHidden') {
            _isLastSeenHidden = !value;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新設定失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, '線上狀態'),
                SwitchListTile(
                  title: const Text('隱藏在線狀態'),
                  subtitle: Text(
                    '開啟後，其他用戶將無法看到您目前是否在線',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  value: _isOnlineStatusHidden,
                  onChanged: (value) => _updateSetting('isOnlineStatusHidden', value),
                  activeTrackColor: theme.colorScheme.primary,
                ),
                SwitchListTile(
                  title: const Text('隱藏最後上線時間'),
                  subtitle: Text(
                    '開啟後，其他用戶將無法看到您最後的上線時間',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  value: _isLastSeenHidden,
                  onChanged: (value) => _updateSetting('isLastSeenHidden', value),
                  activeTrackColor: theme.colorScheme.primary,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '注意：開啟這些選項可能會影響配對功能的體驗。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
