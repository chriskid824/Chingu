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
import 'package:firebase_messaging/firebase_messaging.dart';

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

  // 優化啟動流程：檢查是否有初始通知訊息
  // 這樣可以避免載入預設頁面後再跳轉，提升使用者體驗
  String initialRoute = AppRoutes.mainNavigation;
  Object? initialArguments;

  try {
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      final settings =
          RichNotificationService().getRouteSettings(initialMessage.data);
      if (settings != null && settings.name != null) {
        initialRoute = settings.name!;
        initialArguments = settings.arguments;
        debugPrint('App started from notification: $initialRoute');
      }
    }
  } catch (e) {
    debugPrint('Error handling initial notification: $e');
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
            onGenerateRoute: AppRouter.generateRoute,
            // 處理初始路由堆疊，確保從通知啟動時，返回鍵可以回到主頁
            onGenerateInitialRoutes: (String routeName) {
              if (routeName == AppRoutes.mainNavigation) {
                return [
                  AppRouter.generateRoute(
                    const RouteSettings(name: AppRoutes.mainNavigation),
                  ),
                ];
              }

              return [
                AppRouter.generateRoute(
                  const RouteSettings(name: AppRoutes.mainNavigation),
                ),
                AppRouter.generateRoute(
                  RouteSettings(name: routeName, arguments: initialArguments),
                ),
              ];
            },
          );
        },
      ),
    );
  }
}
