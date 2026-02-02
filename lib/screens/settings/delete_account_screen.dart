import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStep = 0;
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _isConfirmed = false;

  final List<String> _reasons = [
    '找到伴侶了',
    '覺得不實用',
    '隱私疑慮',
    '遇到技術問題',
    '其他',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('未登入');

      final userData = await _firestoreService.getUser(user.uid);
      if (userData == null) throw Exception('找不到用戶資料');

      final jsonString = jsonEncode(userData.toMap());
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('資料已複製到剪貼簿')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匯出失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (!_isConfirmed) return;

    setState(() => _isDeleting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('未登入');

      // 1. Delete Firestore Data
      await _firestoreService.deleteUser(user.uid);

      // 2. Delete Auth Account
      await _authService.deleteAccount();

      // 3. Navigate to Login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '刪除失敗，請稍後再試';

        // Check for specific error message about recent login
        if (e.toString().contains('requires-recent-login') ||
            e.toString().contains('最近登入')) {
          errorMessage = '為了安全起見，請登出後重新登入，再嘗試刪除帳號';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '登出',
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
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
        title: const Text('刪除帳號', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _prevPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentStep = index);
        },
        children: [
          _buildStep1(theme, chinguTheme),
          _buildStep2(theme, chinguTheme),
          _buildStep3(theme, chinguTheme),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme, ChinguTheme? chinguTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: chinguTheme?.warning ?? Colors.orange),
          const SizedBox(height: 24),
          Text(
            '刪除帳號前須知',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號是永久性的操作，一旦執行將無法復原。您的個人資料、配對紀錄、聊天訊息都將被永久刪除。',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),
          Text(
            '保留您的數據',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('您可以下載您的個人資料副本以備份。'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isExporting ? null : _exportData,
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: Text(_isExporting ? '匯出中...' : '匯出我的資料'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme, ChinguTheme? chinguTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想要離開？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('您的回饋能幫助我們改進服務。'),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                ..._reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: theme.colorScheme.primary,
                )),
                if (_selectedReason == '其他')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: TextField(
                      controller: _otherReasonController,
                      decoration: const InputDecoration(
                        hintText: '請告訴我們更多...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason != null ? _nextPage : null,
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme, ChinguTheme? chinguTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.delete_forever, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '最終確認',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '您確定要刪除帳號嗎？',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '此動作無法撤銷。如果您改變主意，將需要重新註冊一個新帳號。',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),
          CheckboxListTile(
            value: _isConfirmed,
            onChanged: (value) => setState(() => _isConfirmed = value ?? false),
            title: const Text('我了解此動作將永久刪除我的帳號和所有資料'),
            activeColor: theme.colorScheme.error,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isConfirmed && !_isDeleting) ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認刪除'),
                    content: const Text('真的要說再見了嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAccount();
                        },
                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                        child: const Text('刪除帳號'),
                      ),
                    ],
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('永久刪除帳號'),
            ),
          ),
        ],
      ),
    );
  }
}
