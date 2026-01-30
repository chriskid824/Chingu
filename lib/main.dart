import 'dart:convert';
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

  // 啟動並行初始化 (非 Firebase 依賴)
  final richNotificationInit = RichNotificationService().initialize();
  final dateFormattingInit = initializeDateFormatting('zh_TW', null);

  // 初始化 Firebase (關鍵依賴)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 啟動 Firebase 相關初始化 (並行)
  final crashReportingInit = CrashReportingService().initialize();
  final fcmInitialMessageFuture = FirebaseMessaging.instance.getInitialMessage();

  // 等待所有初始化完成
  await Future.wait([
    richNotificationInit,
    dateFormattingInit,
    crashReportingInit,
  ]);

  // 獲取通知啟動數據
  final initialMessage = await fcmInitialMessageFuture;
  final localLaunchDetails = await RichNotificationService().getNotificationAppLaunchDetails();

  // 解析通知目標
  RouteSettings? initialNotificationRoute;

  if (initialMessage != null) {
    // 來自 FCM 啟動
    final data = initialMessage.data;
    if (data.isNotEmpty) {
       final actionType = data['actionType'];
       final actionData = data['actionData'];

       if (actionType != null) {
          initialNotificationRoute = _getRouteSettings(actionType, actionData);
       }
    }
  } else if (localLaunchDetails?.didNotificationLaunchApp == true) {
    // 來自本地通知啟動
    final payload = localLaunchDetails?.notificationResponse?.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(payload);
        final actionType = data['actionType'];
        final actionData = data['actionData'];
         if (actionType != null) {
          initialNotificationRoute = _getRouteSettings(actionType, actionData);
       }
      } catch (e) {
        debugPrint('Error parsing launch payload: $e');
      }
    }
  }

  runApp(ChinguApp(initialNotificationRoute: initialNotificationRoute));
}

RouteSettings? _getRouteSettings(String actionType, String? actionData) {
    // 嘗試將 actionData 封裝為參數，以便未來擴展或特定頁面使用
    // 注意：需確保目標頁面的 AppRouter 處理邏輯兼容此參數類型
    final args = actionData != null ? {'id': actionData} : null;

    switch (actionType) {
      case 'open_chat':
        return RouteSettings(name: AppRoutes.chatList, arguments: args);
      case 'view_event':
        return RouteSettings(name: AppRoutes.eventDetail, arguments: args);
      case 'match_history':
        return RouteSettings(name: AppRoutes.matchesList, arguments: args);
      default:
        return const RouteSettings(name: AppRoutes.notifications);
    }
}

class ChinguApp extends StatelessWidget {
  final RouteSettings? initialNotificationRoute;

  const ChinguApp({
    super.key,
    this.initialNotificationRoute,
  });

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
            onGenerateInitialRoutes: (initialRouteName) {
               List<Route<dynamic>> routes = [
                 AppRouter.generateRoute(const RouteSettings(name: AppRoutes.mainNavigation)),
               ];
               if (initialNotificationRoute != null) {
                 routes.add(AppRouter.generateRoute(initialNotificationRoute!));
               }
               return routes;
            },
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
