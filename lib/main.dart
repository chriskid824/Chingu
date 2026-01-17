import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 初始化 Crashlytics
  await CrashReportingService().initialize();

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  // 檢查是否從通知啟動
  String? initialRoute;
  Object? initialArgs;

  try {
    // 檢查是否有初始訊息 (從終止狀態啟動)
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    // 確保使用者已登入才處理通知跳轉
    if (initialMessage != null && FirebaseAuth.instance.currentUser != null) {
      final data = initialMessage.data;
      final actionType = data['actionType'];
      // final actionData = data['actionData']; // Available for future use

      if (actionType != null) {
        switch (actionType) {
          case 'open_chat':
            // 導航到 MainScreen 並切換到聊天頁籤 (Index 3)
            initialRoute = AppRoutes.mainNavigation;
            initialArgs = {'initialIndex': 3};
            break;
          case 'view_event':
            initialRoute = AppRoutes.eventDetail;
            break;
          case 'match_history':
            initialRoute = AppRoutes.matchesList;
            break;
          default:
            initialRoute = AppRoutes.notifications;
            break;
        }
      }
    }
  } catch (e) {
    debugPrint('Error handling initial notification: $e');
  }

  runApp(ChinguApp(
    initialRoute: initialRoute,
    initialArgs: initialArgs,
  ));
}

class ChinguApp extends StatelessWidget {
  final String? initialRoute;
  final Object? initialArgs;

  const ChinguApp({
    super.key,
    this.initialRoute,
    this.initialArgs,
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
            initialRoute: initialRoute ?? AppRoutes.mainNavigation,
            onGenerateInitialRoutes: (initialRouteName) {
              // 預設路由列表 (MainScreen)
              List<Route<dynamic>> routes = [
                AppRouter.generateRoute(const RouteSettings(name: AppRoutes.mainNavigation))
              ];

              // 如果有指定初始路由且需要傳參數給 mainNavigation (例如 open_chat)
              if (initialRouteName == AppRoutes.mainNavigation && initialArgs != null) {
                routes = [
                  AppRouter.generateRoute(
                    RouteSettings(name: AppRoutes.mainNavigation, arguments: initialArgs)
                  )
                ];
              }
              // 如果是其他路由，則堆疊在 MainScreen 之上
              else if (initialRouteName != AppRoutes.mainNavigation) {
                routes.add(
                  AppRouter.generateRoute(
                    RouteSettings(name: initialRouteName, arguments: initialArgs)
                  )
                );
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
