import 'package:flutter/material.dart';

/// 路由名稱常量及導航鍵
class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
}
