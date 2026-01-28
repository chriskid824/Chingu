import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isExportRequested = false;

  @override
  void dispose() {
    _pageController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.requestDataExport(user.uid);
        setState(() {
          _isExportRequested = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('資料匯出請求已發送')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('請求失敗: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_confirmController.text != 'DELETE') return;

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // 先刪除 Firestore 資料
        await _firestoreService.deleteUser(user.uid);
        // 再刪除 Auth 帳號
        await _authService.deleteAccount();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('刪除帳號'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWarningStep(theme),
                _buildExportStep(theme),
                _buildConfirmStep(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '您確定要離開嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號是不可逆的動作。您將會失去：',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoItem(theme, Icons.favorite, '所有的配對紀錄'),
          _buildInfoItem(theme, Icons.chat, '所有的聊天訊息'),
          _buildInfoItem(theme, Icons.person, '個人資料與設定'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildExportStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '保留您的回憶',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，您可以請求匯出您的個人資料副本。我們會在準備好後寄送給您。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (_isExportRequested)
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: theme.colorScheme.primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 children: [
                   Icon(Icons.check_circle, color: theme.colorScheme.primary),
                   const SizedBox(width: 12),
                   const Expanded(child: Text('匯出請求已接收')),
                 ],
               ),
             )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleExport,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: const Text('請求匯出資料'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isExportRequested ? '繼續' : '跳過並繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_forever_rounded, size: 80, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '最終確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '請在下方輸入 "DELETE" 以確認刪除帳號。此動作無法復原。',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textAlign: TextAlign.center,
            onChanged: (value) => setState(() {}),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmController.text == 'DELETE' && !_isLoading
                  ? _handleDelete
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('確認刪除帳號'),
            ),
          ),
        ],
      ),
    );
  }
}
