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

  // 初始化 FCM 通知服務
  try {
    await NotificationService().initialize();

    // 註冊後台訊息處理器
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Failed to initialize NotificationService: $e');
  }

  // 檢查是否從終止狀態啟動
  String? initialRoute;
  Object? initialArguments;

  try {
    final initialRouteInfo = await NotificationService().getInitialNotificationRoute();

    if (initialRouteInfo != null) {
      initialRoute = initialRouteInfo['route'] as String?;
      initialArguments = initialRouteInfo['arguments'];
    }
  } catch (e) {
    debugPrint('Failed to get initial notification route: $e');
  }

  runApp(ChinguApp(
    initialRoute: initialRoute,
    initialArguments: initialArguments,
  ));
}

class ChinguApp extends StatelessWidget {
  final String? initialRoute;
  final Object? initialArguments;

  const ChinguApp({
    super.key,
    this.initialRoute,
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
            initialRoute: initialRoute ?? AppRoutes.mainNavigation,
            onGenerateRoute: (settings) {
              if (initialRoute != null && settings.name == initialRoute && initialArguments != null) {
                return AppRouter.generateRoute(
                  RouteSettings(
                    name: settings.name,
                    arguments: initialArguments,
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
