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

  // 獲取初始訊息 (如果 App 是從通知啟動的)
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  String initialRoute = AppRoutes.mainNavigation;
  Object? initialRouteArgs;

  if (initialMessage != null) {
    // 解析通知資料
    final data = initialMessage.data;
    final actionType = data['actionType'];

    // 將所有通知資料作為參數傳遞
    initialRouteArgs = data;

    // 根據 actionType 決定目標頁面
    switch (actionType) {
      case 'open_chat':
        initialRoute = AppRoutes.chatList;
        break;
      case 'view_event':
        initialRoute = AppRoutes.eventDetail;
        break;
      case 'match_history':
        initialRoute = AppRoutes.matchesList;
        break;
    }
  }

  // 初始化 Crashlytics
  await CrashReportingService().initialize();

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  runApp(ChinguApp(
    initialRoute: initialRoute,
    initialRouteArgs: initialRouteArgs,
  ));
}

class ChinguApp extends StatelessWidget {
  final String initialRoute;
  final Object? initialRouteArgs;

  const ChinguApp({
    super.key,
    this.initialRoute = AppRoutes.mainNavigation,
    this.initialRouteArgs,
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
            onGenerateInitialRoutes: (String routeName) {
              final List<Route<dynamic>> routes = [];

              // 始終先加入 Splash 頁面作為底層
              routes.add(AppRouter.generateRoute(
                const RouteSettings(name: AppRoutes.splash)
              ));

              // 如果目標不是 Splash，則加入目標頁面並帶上參數
              if (routeName != AppRoutes.splash) {
                routes.add(AppRouter.generateRoute(
                  RouteSettings(name: routeName, arguments: initialRouteArgs)
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
