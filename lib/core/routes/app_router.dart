import 'package:flutter/material.dart';
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
import '../../screens/home/search_screen.dart';
// 個人資料模組
import '../../screens/profile/profile_setup_screen.dart';
import '../../screens/profile/interests_selection_screen.dart';
import '../../screens/profile/preferences_screen.dart';
import '../../screens/profile/profile_detail_screen.dart';
import '../../screens/profile/profile_preview_screen.dart';
import '../../screens/profile/favorites_screen.dart';
// Models
import '../../models/user_model.dart';
// Onboarding
import '../../screens/onboarding/location_screen.dart';
import '../../screens/onboarding/notification_permission_screen.dart';
// 配對模組
import '../../screens/matching/matching_screen.dart';
import '../../screens/matching/user_detail_screen.dart';
import '../../screens/matching/matches_list_screen.dart';
import '../../screens/matching/filter_screen.dart';
import '../../screens/matching/match_success_screen.dart';
// 活動模組
import '../../screens/events/events_list_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/events/event_confirmation_screen.dart';
import '../../screens/events/event_rating_screen.dart';
// 聊天模組
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/chat/icebreaker_screen.dart';
import '../../screens/chat/sticker_manager_screen.dart';
// 設定模組
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/settings/privacy_settings_screen.dart';
import '../../screens/settings/notification_settings_screen.dart';
import '../../screens/settings/notification_preview_screen.dart';
import '../../screens/settings/help_center_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/debug/debug_screen.dart';
import '../../screens/profile/report_user_screen.dart';

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
  static const String search = '/search';
  
  // 個人資料設置流程
  static const String profileSetup = '/profile-setup';
  static const String interestsSelection = '/interests-selection';
  static const String preferences = '/preferences';
  static const String location = '/location';
  static const String notificationPermission = '/notification-permission';
  static const String profileDetail = '/profile-detail';
  static const String profilePreview = '/profile-preview';
  
  // 配對模組
  static const String matching = '/matching';
  static const String userDetail = '/user-detail';
  static const String matchesList = '/matches-list';
  static const String filter = '/filter';
  static const String matchSuccess = '/match-success';
  
  // 活動模組
  static const String eventsList = '/events-list';
  static const String eventDetail = '/event-detail';
  static const String eventConfirmation = '/event-confirmation';
  static const String eventRating = '/event-rating';
  
  // 聊天模組
  static const String chatList = '/chat-list';
  static const String chatDetail = '/chat-detail';
  static const String icebreaker = '/icebreaker';
  static const String stickerManager = '/sticker-manager';
  
  // 設定模組
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String privacySettings = '/privacy-settings';
  static const String notificationSettings = '/notification-settings';
  static const String notificationPreview = '/notification-preview';
  static const String helpCenter = '/help-center';
  static const String about = '/about';
  static const String reportUser = '/report-user';
  static const String favorites = '/favorites';
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
        return MaterialPageRoute(builder: (_) => const DebugScreen());
      
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      case AppRoutes.emailVerification:
        return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());
      
      // ==================== 主導航 ====================
      case AppRoutes.mainNavigation:
        final args = settings.arguments;
        final initialIndex = args is Map<String, dynamic> ? args['initialIndex'] as int? : null;
        return MaterialPageRoute(
          builder: (_) => MainScreen(initialIndex: initialIndex),
        );
      
      // ==================== 首頁子頁面 ====================
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      
      // ==================== 個人資料流程 ====================
      case AppRoutes.profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      
      case AppRoutes.interestsSelection:
        return MaterialPageRoute(builder: (_) => const InterestsSelectionScreen());
      
      case AppRoutes.preferences:
        return MaterialPageRoute(builder: (_) => const PreferencesScreen());

      case AppRoutes.location:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      
      case AppRoutes.notificationPermission:
        return MaterialPageRoute(builder: (_) => const NotificationPermissionScreen());

      case AppRoutes.profileDetail:
        return MaterialPageRoute(builder: (_) => const ProfileDetailScreen());
      
      case AppRoutes.profilePreview:
        return MaterialPageRoute(builder: (_) => const ProfilePreviewScreen());

      case AppRoutes.favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());

      // ==================== 配對模組 ====================
      case AppRoutes.matching:
        return MaterialPageRoute(builder: (_) => const MatchingScreen());
      
      case AppRoutes.userDetail:
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(builder: (_) => UserDetailScreen(user: user));
      
      case AppRoutes.matchesList:
        return MaterialPageRoute(builder: (_) => const MatchesListScreen());
      
      case AppRoutes.filter:
        return MaterialPageRoute(builder: (_) => const FilterScreen());
      
      // ==================== 活動模組 ====================
      case AppRoutes.eventsList:
        return MaterialPageRoute(builder: (_) => const EventsListScreen());
      
      case AppRoutes.eventDetail:
        return MaterialPageRoute(builder: (_) => const EventDetailScreen());
      
      case AppRoutes.eventConfirmation:
        return MaterialPageRoute(builder: (_) => const EventConfirmationScreen());
      
      case AppRoutes.eventRating:
        return MaterialPageRoute(builder: (_) => const EventRatingScreen());
      
      // ==================== 聊天模組 ====================
      case AppRoutes.chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      
      case AppRoutes.chatDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatDetailScreen(),
        );
      
      case AppRoutes.icebreaker:
        return MaterialPageRoute(builder: (_) => const IcebreakerScreen());
      
      case AppRoutes.stickerManager:
        return MaterialPageRoute(builder: (_) => const StickerManagerScreen());

      // ==================== 設定模組 ====================
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      
      case AppRoutes.privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      
      case AppRoutes.notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
      
      case AppRoutes.notificationPreview:
        return MaterialPageRoute(builder: (_) => const NotificationPreviewScreen());

      case AppRoutes.helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());

      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case AppRoutes.reportUser:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Error: Missing arguments for report user')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ReportUserScreen(
            reportedUserId: args['reportedUserId'],
            reportedUserName: args['reportedUserName'],
          ),
        );
      
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
  
  /// 自定義頁面切換動畫（從右往左滑入）
  static Route<dynamic> slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
  
  /// 淡入淡出動畫
  static Route<dynamic> fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}











