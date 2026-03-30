import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:chingu/core/theme/app_theme.dart';

// 導入所有 Demo 介面
import 'screens/auth/splash_screen_demo.dart';
import 'screens/auth/login_screen_demo.dart';
import 'screens/auth/register_screen_demo.dart';
import 'screens/auth/forgot_password_screen_demo.dart';
import 'screens/auth/email_verification_screen_demo.dart';
import 'screens/profile/profile_setup_screen_demo.dart';
import 'screens/profile/interests_selection_screen_demo.dart';
import 'screens/profile/preferences_screen_demo.dart';
import 'screens/profile/profile_detail_screen_demo.dart';
import 'screens/home/home_screen_demo.dart';
import 'screens/home/notifications_screen_demo.dart';
import 'screens/home/bottom_nav_demo.dart';
import 'screens/chat/chat_list_screen_demo.dart';
import 'screens/chat/chat_detail_screen_demo.dart';
import 'screens/chat/icebreaker_screen_demo.dart';
import 'screens/settings/settings_screen_demo.dart';
import 'screens/settings/edit_profile_screen_demo.dart';
import 'screens/settings/privacy_settings_screen_demo.dart';
import 'screens/settings/notification_settings_screen_demo.dart';
import 'screens/settings/help_center_screen_demo.dart';
import 'screens/settings/about_screen_demo.dart';
import 'screens/common/loading_screen_demo.dart';
import 'screens/common/error_screen_demo.dart';
import 'screens/common/empty_state_screen_demo.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        // 🔐 認證模組
        WidgetbookFolder(
          name: '🔐 認證模組 (5個)',
          children: [
            WidgetbookComponent(name: '啟動頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const SplashScreenDemo())]),
            WidgetbookComponent(name: '登入頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const LoginScreenDemo())]),
            WidgetbookComponent(name: '註冊頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const RegisterScreenDemo())]),
            WidgetbookComponent(name: '忘記密碼', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ForgotPasswordScreenDemo())]),
            WidgetbookComponent(name: '郵件驗證', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const EmailVerificationScreenDemo())]),
          ],
        ),

        // 👤 個人資料模組
        WidgetbookFolder(
          name: '👤 個人資料模組 (4個)',
          children: [
            WidgetbookComponent(name: '個人資料設定', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ProfileSetupScreenDemo())]),
            WidgetbookComponent(name: '興趣選擇', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const InterestsSelectionScreenDemo())]),
            WidgetbookComponent(name: '配對偏好', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const PreferencesScreenDemo())]),
            WidgetbookComponent(name: '個人資料詳情', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ProfileDetailScreenDemo())]),
          ],
        ),

        // 🏠 首頁與導航
        WidgetbookFolder(
          name: '🏠 首頁與導航 (3個)',
          children: [
            WidgetbookComponent(name: '首頁', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const HomeScreenDemo())]),
            WidgetbookComponent(name: '通知頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const NotificationsScreenDemo())]),
            WidgetbookComponent(name: '底部導航欄', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const BottomNavDemo())]),
          ],
        ),

        // 💬 聊天模組
        WidgetbookFolder(
          name: '💬 聊天模組 (3個)',
          children: [
            WidgetbookComponent(name: '聊天列表', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ChatListScreenDemo())]),
            WidgetbookComponent(name: '聊天詳情', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ChatDetailScreenDemo())]),
            WidgetbookComponent(name: '破冰話題', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const IcebreakerScreenDemo())]),
          ],
        ),

        // ⚙️ 設定模組
        WidgetbookFolder(
          name: '⚙️ 設定模組 (6個)',
          children: [
            WidgetbookComponent(name: '設定頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => ChangeNotifierProvider(create: (_) => ThemeController(), child: const SettingsScreenDemo()))]),
            WidgetbookComponent(name: '編輯個人資料', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const EditProfileScreenDemo())]),
            WidgetbookComponent(name: '隱私設定', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const PrivacySettingsScreenDemo())]),
            WidgetbookComponent(name: '通知設定', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const NotificationSettingsScreenDemo())]),
            WidgetbookComponent(name: '幫助中心', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const HelpCenterScreenDemo())]),
            WidgetbookComponent(name: '關於', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const AboutScreenDemo())]),
          ],
        ),

        // 🔧 其他功能
        WidgetbookFolder(
          name: '🔧 其他功能 (3個)',
          children: [
            WidgetbookComponent(name: '載入頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const LoadingScreenDemo())]),
            WidgetbookComponent(name: '錯誤頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const ErrorScreenDemo())]),
            WidgetbookComponent(name: '空狀態頁面', useCases: [WidgetbookUseCase(name: 'Default', builder: (context) => const EmptyStateScreenDemo())]),
          ],
        ),
      ],
      appBuilder: (context, child) {
        return MaterialApp(home: child);
      },
      addons: [
        DeviceFrameAddon(
          devices: [Devices.ios.iPhone13, Devices.ios.iPhone13ProMax, Devices.android.samsungGalaxyS20, Devices.android.smallPhone],
          initialDevice: Devices.ios.iPhone13,
        ),
        ThemeAddon(
          themes: [
            WidgetbookTheme(name: '🟠 溫暖橙色（原本）', data: AppTheme.themeFor(AppThemePreset.orange)),
            WidgetbookTheme(name: '🟣 極簡紫色（新）', data: AppTheme.themeFor(AppThemePreset.minimal)),
            WidgetbookTheme(name: '🔵 藍色', data: AppTheme.themeFor(AppThemePreset.blue)),
            WidgetbookTheme(name: '🟢 綠色', data: AppTheme.themeFor(AppThemePreset.green)),
            WidgetbookTheme(name: '🟣 紫色', data: AppTheme.themeFor(AppThemePreset.purple)),
            WidgetbookTheme(name: '🩷 粉色', data: AppTheme.themeFor(AppThemePreset.pink)),
          ],
          themeBuilder: (context, theme, child) => Theme(data: theme, child: child),
        ),
        TextScaleAddon(scales: [0.8, 1.0, 1.2, 1.5, 2.0], initialScale: 1.0),
        AlignmentAddon(),
      ],
    );
  }
}