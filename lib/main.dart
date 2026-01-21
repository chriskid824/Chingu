import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/rich_notification_service.dart';

void main() async {
  // 確保 Flutter 綁定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 初始化 Crashlytics
  await CrashReportingService().initialize();

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  // 檢查是否有初始通知訊息 (冷啟動優化)
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  String initialRoute = AppRoutes.mainNavigation;
  Object? initialArguments;

  if (initialMessage != null) {
    final data = initialMessage.data;
    // 嘗試解析 actionType 與 actionData
    String? actionType = data['actionType'];
    String? actionData = data['actionData'];

    // 如果 data 是一個 json string (某些發送方式)
    if (actionType == null && data['payload'] != null) {
       try {
         final payloadMap = json.decode(data['payload']);
         actionType = payloadMap['actionType'];
         actionData = payloadMap['actionData'];
       } catch (_) {}
    }

    switch (actionType) {
      case 'open_chat':
         // 導航到聊天 Tab (Index 3)
         initialRoute = AppRoutes.mainNavigation;
         // 如果有 actionData (例如 chatRoomId)，也可以考慮傳遞
         initialArguments = {'initialIndex': 3};
         break;
      case 'view_event':
         // 導航到活動詳情
         initialRoute = AppRoutes.eventDetail;
         // 嘗試傳遞 eventId
         if (actionData != null) {
            initialArguments = {'eventId': actionData};
         }
         break;
      case 'match_history':
         // 導航到配對列表
         initialRoute = AppRoutes.matchesList;
         break;
      default:
         // 預設導航到通知頁面
         if (actionType != null || initialMessage.notification != null) {
            initialRoute = AppRoutes.notifications;
         }
         break;
    }
  }

  runApp(ChinguApp(
    initialRoute: initialRoute,
    initialArguments: initialArguments,
  ));
}

class ChinguApp extends StatelessWidget {
  final String initialRoute;
  final Object? initialArguments;

  const ChinguApp({
    super.key,
    this.initialRoute = AppRoutes.mainNavigation,
    this.initialArguments,
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
            initialRoute: initialRoute,
            onGenerateInitialRoutes: (initialRouteName) {
              List<Route<dynamic>> routes = [];

              // 基礎路由：主導航
              // 如果目標是 mainNavigation 且有參數 (例如切換 Tab)，則直接使用該參數
              if (initialRouteName == AppRoutes.mainNavigation && initialArguments != null) {
                 routes.add(AppRouter.generateRoute(
                    RouteSettings(name: initialRouteName, arguments: initialArguments)
                 ));
                 return routes;
              }

              // 基礎路由
              routes.add(AppRouter.generateRoute(
                  const RouteSettings(name: AppRoutes.mainNavigation)
              ));

              // 如果有其他目標路由，疊加在主導航之上
              if (initialRouteName != AppRoutes.mainNavigation) {
                routes.add(AppRouter.generateRoute(
                    RouteSettings(name: initialRouteName, arguments: initialArguments)
                ));
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
