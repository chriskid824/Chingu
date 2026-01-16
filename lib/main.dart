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

void main() async {
  // 確保 Flutter 綁定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 平行初始化服務以優化啟動速度
  await Future.wait([
    CrashReportingService().initialize(),
    initializeDateFormatting('zh_TW', null),
    RichNotificationService().initialize(),
  ]);

  // 獲取啟動通知資料
  final initialNotificationData = await RichNotificationService().getLaunchNotification();

  runApp(ChinguApp(initialNotificationData: initialNotificationData));
}

class ChinguApp extends StatelessWidget {
  final Map<String, dynamic>? initialNotificationData;

  const ChinguApp({
    super.key,
    this.initialNotificationData,
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
              // 默認路由
              var routes = [
                AppRouter.generateRoute(RouteSettings(name: initialRoute)),
              ];

              if (initialNotificationData != null) {
                final actionType = initialNotificationData!['actionType'];
                final actionData = initialNotificationData!['actionData'];

                if (actionType == 'open_chat') {
                  // 如果是聊天，直接跳轉到聊天 Tab (index 3)
                  routes = [
                    AppRouter.generateRoute(
                      const RouteSettings(
                        name: AppRoutes.mainNavigation,
                        arguments: {'initialIndex': 3},
                      ),
                    ),
                  ];
                } else if (actionType == 'view_event') {
                  routes.add(
                    AppRouter.generateRoute(
                      RouteSettings(
                        name: AppRoutes.eventDetail,
                        arguments: actionData,
                      ),
                    ),
                  );
                } else if (actionType == 'match_history') {
                  routes.add(
                    AppRouter.generateRoute(
                      const RouteSettings(name: AppRoutes.matchesList),
                    ),
                  );
                } else {
                  // 預設跳轉到通知頁
                  routes.add(
                    AppRouter.generateRoute(
                      const RouteSettings(name: AppRoutes.notifications),
                    ),
                  );
                }
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
