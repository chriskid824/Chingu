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
import 'services/rich_notification_service.dart';
import 'services/notification_service.dart';

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

  // 初始化通知服務 (FCM) 並獲取初始通知動作
  final notificationService = NotificationService();
  await notificationService.initialize();
  final initialRouteAction = await notificationService.getInitialNotificationAction();

  runApp(ChinguApp(
    initialRouteName: initialRouteAction?.routeName,
    initialRouteArgs: initialRouteAction?.arguments,
  ));
}

class ChinguApp extends StatelessWidget {
  final String? initialRouteName;
  final Object? initialRouteArgs;

  const ChinguApp({
    super.key,
    this.initialRouteName,
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
            onGenerateRoute: AppRouter.generateRoute,
            onGenerateInitialRoutes: (initialRoute) {
              // 構建路由堆疊
              final List<Route<dynamic>> routes = [
                AppRouter.generateRoute(const RouteSettings(name: AppRoutes.mainNavigation)),
              ];

              // 如果有來自通知的初始路由，且不等於主導航，則加入堆疊
              if (initialRouteName != null && initialRouteName != AppRoutes.mainNavigation) {
                routes.add(AppRouter.generateRoute(
                  RouteSettings(name: initialRouteName, arguments: initialRouteArgs),
                ));
              } else if (initialRouteName == AppRoutes.mainNavigation && initialRouteArgs != null) {
                // 如果是主導航但有參數（例如切換 Tab），則替換第一個路由
                routes[0] = AppRouter.generateRoute(
                  RouteSettings(name: AppRoutes.mainNavigation, arguments: initialRouteArgs),
                );
              }

              return routes;
            },
          );
        },
      ),
    );
  }
}
