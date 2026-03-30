import 'package:flutter/material.dart';
import '../theme/app_animations.dart';
// 認證模組
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
// 主導航
import '../../screens/main_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/notifications_screen.dart';
// 個人資料模組
import '../../screens/profile/profile_setup_screen.dart';
import '../../screens/profile/interests_selection_screen.dart';
import '../../screens/profile/preferences_screen.dart';
import '../../screens/profile/profile_detail_screen.dart';
// Onboarding
import '../../screens/onboarding/location_screen.dart';
import '../../screens/onboarding/notification_permission_screen.dart';
// 聊天模組
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/chat/icebreaker_screen.dart';
// 評價模組
import '../../screens/review/review_screen.dart';
// 設定模組
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/settings/edit_preferences_screen.dart';
import '../../screens/settings/privacy_settings_screen.dart';
import '../../screens/settings/notification_settings_screen.dart';
import '../../screens/settings/notification_preview_screen.dart';
import '../../screens/settings/help_center_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/settings/blocked_users_screen.dart';
import '../../screens/debug/debug_screen.dart';
import '../../screens/profile/report_user_screen.dart';
// 群組模組
import '../../screens/group/group_detail_screen.dart';
import '../../models/dinner_group_model.dart';
// Events 模組
import '../../screens/events/event_detail_screen.dart';
import '../../models/dinner_event_model.dart';

/// 路由名稱常量
class AppRoutes {
  // 認證路由
  static const String splash = '/';
  static const String debug = '/debug';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  
  // 主導航
  static const String mainNavigation = '/main';
  static const String home = '/home';
  static const String notifications = '/notifications';
  
  // 個人資料設置流程
  static const String profileSetup = '/profile-setup';
  static const String interestsSelection = '/interests-selection';
  static const String preferences = '/preferences';
  static const String location = '/location';
  static const String notificationPermission = '/notification-permission';
  static const String profileDetail = '/profile-detail';
  // 聊天模組
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';
  static const String icebreaker = '/icebreaker';
  static const String review = '/review';
  
  // 設定模組
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String editPreferences = '/edit-preferences';
  static const String privacySettings = '/privacy-settings';
  static const String notificationSettings = '/notification-settings';
  static const String notificationPreview = '/notification-preview';
  static const String helpCenter = '/help-center';
  static const String about = '/about';
  static const String reportUser = '/report-user';
  static const String blockedUsers = '/blocked-users';
  
  // 群組模組
  static const String groupDetail = '/group-detail';
  
  // Events 模組
  static const String eventDetail = '/event-detail';
  
}

/// 應用程式路由配置
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== 認證路由 ====================
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.debug:
        return _chinguRoute(const DebugScreen());

      case AppRoutes.login:
        return _chinguRoute(const LoginScreen());

      case AppRoutes.register:
        return _chinguRoute(const RegisterScreen());

      case AppRoutes.forgotPassword:
        return _chinguRoute(const ForgotPasswordScreen());

      case AppRoutes.emailVerification:
        return _chinguRoute(const EmailVerificationScreen());

      // ==================== 主導航 ====================
      case AppRoutes.mainNavigation:
        final args = settings.arguments;
        final initialIndex = args is Map<String, dynamic> ? args['initialIndex'] as int? : null;
        return MaterialPageRoute(
          builder: (_) => MainScreen(initialIndex: initialIndex),
        );

      // ==================== 首頁子頁面 ====================
      case AppRoutes.home:
        return _chinguRoute(const HomeScreen());

      case AppRoutes.notifications:
        return _chinguRoute(const NotificationsScreen());

      // ==================== 個人資料流程 ====================
      case AppRoutes.profileSetup:
        return _chinguRoute(const ProfileSetupScreen());

      case AppRoutes.interestsSelection:
        return _chinguRoute(const InterestsSelectionScreen());

      case AppRoutes.preferences:
        return _chinguRoute(const PreferencesScreen());

      case AppRoutes.editPreferences:
        return _chinguRoute(const EditPreferencesScreen());

      case AppRoutes.location:
        return _chinguRoute(const LocationScreen());

      case AppRoutes.notificationPermission:
        return _chinguRoute(const NotificationPermissionScreen());

      case AppRoutes.profileDetail:
        return _chinguRoute(const ProfileDetailScreen());

      // ==================== 聊天模組 ====================
      case AppRoutes.chatList:
        return _chinguRoute(const ChatListScreen());

      case AppRoutes.chatDetail:
        return _chinguRoute(const ChatDetailScreen(), settings: settings);

      case AppRoutes.icebreaker:
        return _chinguRoute(const IcebreakerScreen());

      case AppRoutes.review:
        return _chinguRoute(const ReviewScreen(), settings: settings);

      // ==================== 設定模組 ====================
      case AppRoutes.settings:
        return _chinguRoute(const SettingsScreen());

      case AppRoutes.editProfile:
        return _chinguRoute(const EditProfileScreen());

      case AppRoutes.privacySettings:
        return _chinguRoute(const PrivacySettingsScreen());

      case AppRoutes.notificationSettings:
        return _chinguRoute(const NotificationSettingsScreen());

      case AppRoutes.notificationPreview:
        return _chinguRoute(const NotificationPreviewScreen());

      case AppRoutes.helpCenter:
        return _chinguRoute(const HelpCenterScreen());

      case AppRoutes.about:
        return _chinguRoute(const AboutScreen());

      case AppRoutes.reportUser:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _chinguRoute(
            const Scaffold(
              body: Center(child: Text('Error: Missing arguments for report user')),
            ),
          );
        }
        return _chinguRoute(ReportUserScreen(
          reportedUserId: args['reportedUserId'],
          reportedUserName: args['reportedUserName'],
        ));

      case AppRoutes.blockedUsers:
        return _chinguRoute(const BlockedUsersScreen());

      // ==================== 群組路由 ====================
      case AppRoutes.groupDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final group = args['group'] as DinnerGroupModel;
        return _chinguRoute(GroupDetailScreen(group: group));

      // ==================== Events 模組 ====================
      case AppRoutes.eventDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final event = args['event'] as DinnerEventModel;
        final group = args['group'] as DinnerGroupModel?;
        return _chinguRoute(EventDetailScreen(event: event, group: group));

      // ==================== 404 ====================
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('找不到頁面: ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  /// 統一頁面轉場：右滑入 + 淡入，easeOutCubic 350ms
  static Route<dynamic> _chinguRoute(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: AppAnimations.pageTransition,
      reverseTransitionDuration: AppAnimations.pageTransition,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppAnimations.pageTransitionCurve,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// 自定義頁面切換動畫（從右往左滑入）— 使用統一常量
  static Route<dynamic> slideRoute(Widget page) => _chinguRoute(page);

  /// 淡入淡出動畫
  static Route<dynamic> fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: AppAnimations.pageTransition,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppAnimations.pageTransitionCurve,
          ),
          child: child,
        );
      },
    );
  }
}











