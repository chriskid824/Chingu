import 'dart:async';
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
import 'widgets/error_boundary_widget.dart';

void main() async {
  // Use runZonedGuarded to catch global uncaught errors
  runZonedGuarded<Future<void>>(() async {
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

    // Set custom error widget for build phase errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In debug mode, use the default error widget to see the stack trace
      bool isDebug = false;
      assert(() {
        isDebug = true;
        return true;
      }());

      // We can also allow ErrorBoundaryWidget to show details in debug if configured
      return ErrorBoundaryWidget(
        errorDetails: details,
        isDev: isDebug,
      );
    };

    runApp(const ChinguApp());
  }, (error, stack) {
    // Pass to CrashReportingService (which already sets PlatformDispatcher.onError,
    // but runZonedGuarded catches errors in this zone specifically)
    CrashReportingService().recordError(error, stack, fatal: true);
  });
}

class ChinguApp extends StatelessWidget {
  const ChinguApp({super.key});

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
            onGenerateRoute: AppRouter.generateRoute,
            builder: (context, child) {
              // Wrap the entire app with a secondary error catcher if needed,
              // or just return child. ErrorWidget.builder handles build errors.
              // We can also add a global overlay for network errors here later.
              return child!;
            },
          );
        },
      ),
    );
  }
}
