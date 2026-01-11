import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  int _currentPage = 0;
  String _selectedReason = '';
  bool _isExportRequested = false;

  final List<String> _leavingReasons = [
    '找到伴侶了',
    '遇到技術問題',
    '使用體驗不佳',
    '隱私考量',
    '想休息一陣子',
    '其他',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('刪除帳號', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.arrow_back,
          onPressed: () {
            if (_currentPage > 0) {
              _previousPage();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildStep1Warning(theme, chinguTheme!),
                _buildStep2Reason(theme),
                _buildStep3Export(theme, chinguTheme),
                _buildStep4Confirm(theme, chinguTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Warning(ThemeData theme, ChinguTheme chinguTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '確定要離開嗎？',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '刪除帳號後，您所有的資料將被永久移除且無法復原：',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildWarningItem(theme, '個人檔案與照片'),
          _buildWarningItem(theme, '所有的配對紀錄'),
          _buildWarningItem(theme, '所有的聊天訊息'),
          _buildWarningItem(theme, '活動報名紀錄'),
          const Spacer(),
          GradientButton(
            text: '繼續',
            onPressed: _nextPage,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error.withOpacity(0.8),
                theme.colorScheme.error,
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Reason(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '為什麼想離開？',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '您的回饋能幫助我們改善服務',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        ..._leavingReasons.map((reason) => RadioListTile<String>(
          title: Text(reason),
          value: reason,
          groupValue: _selectedReason,
          activeColor: theme.colorScheme.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              _selectedReason = value!;
            });
          },
        )),
        if (_selectedReason == '其他')
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              hintText: '請告訴我們更多...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        const SizedBox(height: 32),
        GradientButton(
          text: '下一步',
          onPressed: _selectedReason.isNotEmpty ? _nextPage : null,
          gradient: _selectedReason.isNotEmpty
              ? null // Use default primary gradient
              : LinearGradient( // Disabled state
                  colors: [
                    theme.disabledColor,
                    theme.disabledColor,
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStep3Export(ThemeData theme, ChinguTheme chinguTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '備份您的資料',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號前，您可以選擇下載您的個人資料備份。這包括您的個人檔案、活動紀錄等。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.surfaceVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('個人資料封存檔 (JSON)')),
                  ],
                ),
                if (_isExportRequested) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    '系統正在準備您的檔案，完成後將寄送至您的信箱。',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (!_isExportRequested)
            OutlinedButton.icon(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.requestDataExport();

                if (!context.mounted) return;

                if (success) {
                  setState(() {
                    _isExportRequested = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('資料匯出請求已送出')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authProvider.errorMessage ?? '請求失敗')),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('申請資料匯出'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          const SizedBox(height: 16),
          GradientButton(
            text: '繼續刪除流程',
            onPressed: _nextPage,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error.withOpacity(0.8),
                theme.colorScheme.error,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Confirm(ThemeData theme, ChinguTheme chinguTheme) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isPasswordProvider = auth.providerId == 'password';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最後確認',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPasswordProvider
              ? '請輸入您的密碼以確認刪除帳號。此動作無法復原。'
              : '請點擊下方按鈕進行驗證以刪除帳號。此動作無法復原。',
            style: TextStyle(
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
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                errorStyle: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const Spacer(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return GradientButton(
                text: auth.isLoading ? '處理中...' : '永久刪除帳號',
                onPressed: auth.isLoading ? null : () async {
                  if (isPasswordProvider && _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請輸入密碼')),
                    );
                    return;
                  }

                  final success = await auth.deleteAccount(
                    password: isPasswordProvider ? _passwordController.text : null,
                  );

                  if (success && mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                },
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.error.withOpacity(0.8),
                    theme.colorScheme.error,
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
