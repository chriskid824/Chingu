import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/dinner_event_provider.dart';
import 'providers/matching_provider.dart';
import 'providers/chat_provider.dart';
import 'services/crash_reporting_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/rich_notification_service.dart';

void main() async {
  // 確保 Flutter 綁定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 並行執行其他初始化工作，優化啟動速度
  final results = await Future.wait([
    CrashReportingService().initialize(),
    initializeDateFormatting('zh_TW', null),
    RichNotificationService().initialize(),
    _getInitialNotificationRoute(),
  ]);

  // 獲取初始路由資訊
  // results[3] 是 _getInitialNotificationRoute() 的回傳值
  final initialRouteInfo = results[3] as Map<String, dynamic>?;

  runApp(ChinguApp(initialRouteInfo: initialRouteInfo));
}

/// 獲取初始通知路由資訊
Future<Map<String, dynamic>?> _getInitialNotificationRoute() async {
  try {
    // 1. 檢查 FCM 初始訊息 (遠端通知)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      // 解析 FCM 數據
      final data = initialMessage.data;
      if (data.isNotEmpty) {
        // 嘗試根據 data 中的欄位決定路由
        // 這裡假設後端發送的 data 結構包含 actionType 或類似欄位
        // 根據 RichNotificationService 的邏輯:
        final actionType = data['actionType'];
        if (actionType != null) {
           return _mapActionToRoute(actionType);
        }
      }
    }

    // 2. 檢查本地通知啟動資訊 (RichNotificationService)
    final localNotificationData = await RichNotificationService().getInitialNotificationData();
    if (localNotificationData != null) {
      return localNotificationData;
    }
  } catch (e) {
    debugPrint('Error getting initial notification route: $e');
  }

  return null;
}

Map<String, dynamic> _mapActionToRoute(String action) {
  switch (action) {
    case 'open_chat':
      return {'route': AppRoutes.chatList};
    case 'view_event':
      return {'route': AppRoutes.eventDetail};
    case 'match_history':
      return {'route': AppRoutes.matchesList};
    default:
      return {'route': AppRoutes.notifications};
  }
}

class ChinguApp extends StatelessWidget {
  final Map<String, dynamic>? initialRouteInfo;

  const ChinguApp({super.key, this.initialRouteInfo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => DinnerEventProvider()),
        ChangeNotifierProvider(create: (_) => MatchingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Chingu - 6人晚餐社交',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            theme: themeController.theme,
            initialRoute: initialRouteInfo != null
                ? initialRouteInfo!['route'] as String
                : AppRoutes.mainNavigation,
            onGenerateRoute: (settings) {
              // 如果是初始路由且有參數，注入參數
              if (settings.name == initialRouteInfo?['route'] && initialRouteInfo?['arguments'] != null) {
                return AppRouter.generateRoute(
                  RouteSettings(
                    name: settings.name,
                    arguments: initialRouteInfo!['arguments'],
                  ),
                );
              }
              return AppRouter.generateRoute(settings);
            },
          );
        },
      ),
    );
  }
}
