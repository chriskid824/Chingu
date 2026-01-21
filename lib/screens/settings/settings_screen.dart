import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('設定', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildHeader(context),
          // Profile Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '張小明',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'user@example.com',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Account Settings
          _buildSectionTitle(context, '帳號設定'),
          _buildListTile(context, Icons.person_outline, '個人資料', () {
            Navigator.of(context).pushNamed(AppRoutes.editProfile);
          }),
          _buildListTile(context, Icons.favorite_outline, '配對偏好', () {
            Navigator.of(context).pushNamed(AppRoutes.preferences);
          }),
          _buildListTile(context, Icons.lock_outline, '隱私設定', () {
            Navigator.of(context).pushNamed(AppRoutes.privacySettings);
          }),
          _buildListTile(context, Icons.notifications_outlined, '通知設定', () {
            Navigator.of(context).pushNamed(AppRoutes.notificationSettings);
          }),
          _buildListTile(context, Icons.history, '登入紀錄', () {
            Navigator.of(context).pushNamed(AppRoutes.loginHistory);
          }),
          const Divider(),
          // App Settings
          _buildSectionTitle(context, '應用程式'),
          _buildListTile(context, Icons.language, '語言', () {}, trailing: ' 繁體中文'),
          _buildListTile(context, Icons.bug_report, '開發者工具', () {
            Navigator.of(context).pushNamed(AppRoutes.debug);
          }),
          const Divider(),
          // Support
          _buildSectionTitle(context, '支援'),
          _buildListTile(context, Icons.help_outline, '幫助中心', () {
            Navigator.of(context).pushNamed(AppRoutes.helpCenter);
          }),
          _buildListTile(context, Icons.feedback_outlined, '意見回饋', () {
            // 可以開啟意見回饋表單或發送email
          }),
          _buildListTile(context, Icons.star_outline, '評價應用程式', () {
            // 可以開啟應用商店評分頁面
          }),
          _buildListTile(context, Icons.info_outline, '關於', () {
            Navigator.of(context).pushNamed(AppRoutes.about);
          }, trailing: 'v1.0.0'),
          const Divider(),
          // Logout
          _buildListTile(
            context,
            Icons.logout,
            '登出',
            () {
              // 顯示確認對話框
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('確認登出'),
                  content: const Text('您確定要登出嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 執行登出邏輯，導向登入頁面
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      child: Text('確定', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );
            },
            textColor: theme.colorScheme.error,
            iconColor: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative circles
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.03),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
          ),
          // Main Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: chinguTheme?.primaryGradient ??
                  LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          // Floating small icons/dots
          Positioned(
            top: 10,
            right: 10,
            child: SizedBox(
               width: 160,
               height: 160,
               child: Stack(
                 children: [
                    Positioned(
                      top: 40,
                      right: 30,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 24,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 30,
                      child: Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                 ]
               )
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
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    dynamic trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      trailing: trailing is String
          ? Text(trailing, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)))
          : trailing is Widget
              ? trailing
              : Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: onTap,
    );
  }
}

