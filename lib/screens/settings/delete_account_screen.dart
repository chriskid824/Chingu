import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _acknowledged = false;
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
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
        title: Text('刪除帳號', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.error));
          }

          return Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    _buildStepIndicator(0, '警告', theme, chinguTheme),
                    _buildStepLine(0, theme),
                    _buildStepIndicator(1, '備份', theme, chinguTheme),
                    _buildStepLine(1, theme),
                    _buildStepIndicator(2, '確認', theme, chinguTheme),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildWarningStep(context, theme),
                    _buildExportStep(context, authProvider, theme),
                    _buildConfirmationStep(context, authProvider, theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, ThemeData theme, ChinguTheme? chinguTheme) {
    final isActive = _currentPage >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? theme.colorScheme.error : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step, ThemeData theme) {
    final isActive = _currentPage > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? theme.colorScheme.error : theme.colorScheme.surfaceContainerHighest,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      ),
    );
  }

  Widget _buildWarningStep(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '刪除帳號是不可逆的',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '如果刪除您的帳號，您將永久失去：',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('所有的個人資料與配對偏好', theme),
          _buildBulletPoint('所有的聊天記錄與配對歷史', theme),
          _buildBulletPoint('所有的活動參加記錄', theme),
          const SizedBox(height: 32),
          const Spacer(),
          CheckboxListTile(
            value: _acknowledged,
            onChanged: (value) {
              setState(() {
                _acknowledged = value ?? false;
              });
            },
            title: const Text('我了解此操作無法復原'),
            activeColor: theme.colorScheme.error,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acknowledged ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove_circle_outline, size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildExportStep(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.save_alt_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '備份您的資料',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '在刪除帳號之前，建議您備份個人資料。您可以將資料複製到剪貼簿並自行保存。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () {
                if (authProvider.userModel != null) {
                   final userData = jsonEncode(authProvider.userModel!.toMap());
                   Clipboard.setData(ClipboardData(text: userData));
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('資料已複製到剪貼簿')),
                   );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('複製個人資料 (JSON)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('點擊複製', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _nextPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('不需要備份，繼續'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.delete_forever_rounded, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 24),
          Text(
            '最後確認',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '請在下方輸入 "DELETE" 以確認刪除帳號。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _confirmationController,
            decoration: InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          if (authProvider.errorMessage != null)
             Text(
               authProvider.errorMessage!,
               style: TextStyle(color: theme.colorScheme.error),
             ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmationController.text == 'DELETE'
                  ? () async {
                      final success = await authProvider.deleteAccount();
                      if (success && context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('確認永久刪除'),
            ),
          ),
        ],
      ),
    );
  }
}
