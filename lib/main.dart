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

  // 平行初始化其他服務
  await Future.wait([
    CrashReportingService().initialize(),
    initializeDateFormatting('zh_TW', null),
    RichNotificationService().initialize(),
  ]);

  // 檢查啟動通知
  final initialRouteInfo = await RichNotificationService().getInitialRoute();

  runApp(ChinguApp(initialRouteInfo: initialRouteInfo));
}

class ChinguApp extends StatelessWidget {
  final NotificationRouteInfo? initialRouteInfo;

  const ChinguApp({super.key, this.initialRouteInfo});

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
            initialRoute: initialRouteInfo?.route ?? AppRoutes.mainNavigation,
            onGenerateRoute: (settings) {
              if (initialRouteInfo != null &&
                  settings.name == initialRouteInfo!.route) {
                return AppRouter.generateRoute(
                  RouteSettings(
                    name: settings.name,
                    arguments: initialRouteInfo!.arguments,
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
