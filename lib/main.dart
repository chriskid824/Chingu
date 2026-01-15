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
import 'services/notification_launch_service.dart';

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

  // 獲取初始路由與參數 (從通知啟動)
  final LaunchContext launchContext = await NotificationLaunchService().getInitialLaunchContext();

  runApp(ChinguApp(launchContext: launchContext));
}

class ChinguApp extends StatelessWidget {
  final LaunchContext launchContext;

  const ChinguApp({
    super.key,
    required this.launchContext,
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
            initialRoute: launchContext.route,
            onGenerateRoute: (settings) {
              // 如果是初始路由，且有參數，則使用傳入的參數
              if (settings.name == launchContext.route && launchContext.arguments != null) {
                return AppRouter.generateRoute(
                  RouteSettings(
                    name: settings.name,
                    arguments: launchContext.arguments,
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
