import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  // 1. 檢查並解析啟動通知 (FCM & Local)
  String? initialActionType;
  String? initialActionData;

  // 檢查 FCM 啟動訊息
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final data = initialMessage.data;
    if (data.containsKey('actionType')) {
      initialActionType = data['actionType'];
      initialActionData = data['actionData'];
    }
  }

  // 如果沒有 FCM 啟動訊息，檢查本地通知
  if (initialActionType == null) {
    final notificationAppLaunchDetails =
        await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        try {
          final data = json.decode(payload);
          initialActionType = data['actionType'];
          initialActionData = data['actionData'];
          // 標記 RichNotificationService 忽略此啟動通知，避免重複導航
          RichNotificationService().suppressLaunchNotification();
        } catch (e) {
          debugPrint('Error parsing local notification payload: $e');
        }
      }
    }
  }

  // 初始化 Crashlytics
  await CrashReportingService().initialize();

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  runApp(ChinguApp(
    initialActionType: initialActionType,
    initialActionData: initialActionData,
  ));
}

class ChinguApp extends StatelessWidget {
  final String? initialActionType;
  final String? initialActionData;

  const ChinguApp({
    super.key,
    this.initialActionType,
    this.initialActionData,
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
            initialRoute: AppRoutes.mainNavigation,
            onGenerateInitialRoutes: (initialRouteName) {
              // 如果有啟動通知動作，生成自定義路由堆疊
              if (initialActionType != null) {
                return _generateInitialRoutes(
                    initialActionType!, initialActionData);
              }
              // 預設路由
              return [
                AppRouter.generateRoute(
                    const RouteSettings(name: AppRoutes.mainNavigation))
              ];
            },
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }

  /// 根據通知動作生成初始路由堆疊
  List<Route<dynamic>> _generateInitialRoutes(
      String actionType, String? actionData) {
    List<Route<dynamic>> routes = [];

    // 根據不同動作決定 Base Route
    // 大多數情況下，我們希望底部是 MainScreen
    // 如果是聊天，我們可以直接設置 MainScreen 的 initialIndex
    if (actionType == 'open_chat') {
      routes.add(AppRouter.generateRoute(
        const RouteSettings(
          name: AppRoutes.mainNavigation,
          arguments: {'initialIndex': 3}, // Chat Tab Index
        ),
      ));
      // 如果有特定的 chatRoomId (actionData)，可以在這裡 push ChatDetail
      // 但根據現有邏輯，暫時只導航到列表
      return routes;
    }

    // 對於其他情況，先加入 MainScreen (預設首頁)
    routes.add(AppRouter.generateRoute(
        const RouteSettings(name: AppRoutes.mainNavigation)));

    // 再疊加目標頁面
    switch (actionType) {
      case 'view_event':
        routes.add(AppRouter.generateRoute(
            const RouteSettings(name: AppRoutes.eventDetail)));
        break;
      case 'match_history':
        routes.add(AppRouter.generateRoute(
            const RouteSettings(name: AppRoutes.matchesList)));
        break;
      // 可擴充其他類型
    }

    return routes;
  }
}
