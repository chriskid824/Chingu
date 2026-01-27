import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
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

  // 1. 優先初始化 Firebase (關鍵路徑)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 平行處理其他非阻塞初始化
  // 使用 Future.wait 加速啟動流程
  await Future.wait([
    CrashReportingService().initialize(),
    initializeDateFormatting('zh_TW', null),
    RichNotificationService().initialize(),
  ]);

  // 3. 檢查通知啟動 (FCM & Local)
  // 檢查是否有初始 FCM 訊息
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  // 檢查是否有初始本地通知
  final localLaunchDetails = await RichNotificationService().getLaunchDetails();

  String? targetRoute;
  Object? targetArgs;

  // 優先處理 FCM
  if (initialMessage != null) {
    final routeInfo = RichNotificationService.getRouteInfo(
      data: initialMessage.data,
    );
    if (routeInfo != null) {
      targetRoute = routeInfo['route'];
      targetArgs = routeInfo['arguments'];
    }
  }
  // 其次處理本地通知
  else if (localLaunchDetails?.didNotificationLaunchApp ?? false) {
    final payload = localLaunchDetails!.notificationResponse?.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(payload);
        final routeInfo = RichNotificationService.getRouteInfo(
          data: data,
          actionId: localLaunchDetails.notificationResponse?.actionId,
        );
        if (routeInfo != null) {
          targetRoute = routeInfo['route'];
          targetArgs = routeInfo['arguments'];
        }
      } catch (e) {
        debugPrint('Error parsing launch payload: $e');
      }
    }
  }

  runApp(ChinguApp(
    initialTargetRoute: targetRoute,
    initialTargetArgs: targetArgs,
  ));
}

class ChinguApp extends StatelessWidget {
  final String? initialTargetRoute;
  final Object? initialTargetArgs;

  const ChinguApp({
    super.key,
    this.initialTargetRoute,
    this.initialTargetArgs,
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
            onGenerateInitialRoutes: (initialRoute) {
              // 構建路由堆疊：Main -> Target
              final List<Route<dynamic>> routes = [
                AppRouter.generateRoute(const RouteSettings(name: AppRoutes.mainNavigation)),
              ];

              if (initialTargetRoute != null && initialTargetRoute != AppRoutes.mainNavigation) {
                routes.add(AppRouter.generateRoute(RouteSettings(
                  name: initialTargetRoute,
                  arguments: initialTargetArgs,
                )));
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
