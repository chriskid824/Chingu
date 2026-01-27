import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 Data
  bool _requestDataExport = false;

  // Step 2 Data
  String? _selectedReason;
  final List<String> _reasons = [
    '找到對象了',
    '應用程式不好用',
    '隱私考量',
    '技術問題',
    '其他原因',
  ];

  // Step 3 Data
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPasswordProvider = authProvider.firebaseUser?.providerData
            .any((p) => p.providerId == 'password') ?? false;

    if (isPasswordProvider && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入密碼以確認')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    // Mock sending data export request if checked
    if (_requestDataExport) {
       // Simulate API call or trigger backend process
       await Future.delayed(const Duration(milliseconds: 500));
       debugPrint('Data export requested for ${authProvider.uid}');
    }

    final success = await authProvider.deleteAccount(
      password: isPasswordProvider ? _passwordController.text : null,
    );

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? '刪除失敗，請重試')),
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
        title: const Text('刪除帳號'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _prevPage();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildWarningStep(theme),
                _buildReasonStep(theme),
                _buildConfirmationStep(theme),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '您確定要刪除帳號嗎？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '此操作無法復原。刪除帳號後，您的個人資料、配對紀錄、聊天訊息和活動紀錄將被永久刪除。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: CheckboxListTile(
              value: _requestDataExport,
              onChanged: (value) => setState(() => _requestDataExport = value ?? false),
              title: const Text('請求匯出我的資料'),
              subtitle: const Text('我們將會把您的資料副本寄送至您的信箱'),
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '為什麼想離開？',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '您的回饋能幫助我們改進服務',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _reasons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reason = _reasons[index];
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(reason, style: theme.textTheme.bodyLarge)),
                        if (isSelected)
                          Icon(Icons.check_circle, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _nextPage, // Optional to enforce selection: _selectedReason != null ? _nextPage : null,
              child: const Text('下一步'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () => setState(() {
                _selectedReason = null;
                _nextPage();
              }),
              child: const Text('跳過'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPasswordProvider = authProvider.firebaseUser?.providerData
            .any((p) => p.providerId == 'password') ?? false;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isPasswordProvider
                ? '為了確保帳號安全，請輸入您的密碼以確認刪除。'
                : '請點擊下方按鈕以驗證並確認刪除帳號。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),

          if (isPasswordProvider)
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密碼',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),

          const Spacer(),

          if (_isDeleting)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _handleDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('確認永久刪除'),
              ),
            ),
        ],
      ),
    );
  }
}
