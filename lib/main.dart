import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/dinner_event_provider.dart';
import 'providers/review_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/dinner_group_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/crash_reporting_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/rich_notification_service.dart';
import 'services/push_notification_service.dart';
import 'screens/auth/auth_gate.dart';

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

  // 初始化豐富通知服務（模擬器上可能失敗）
  try {
    await RichNotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ RichNotification 初始化失敗: $e');
  }

  // 初始化 FCM 推播服務（模擬器上可能失敗，不阻擋 App 啟動）
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ FCM 初始化失敗（模擬器正常）: $e');
  }

  runApp(const ChinguApp());
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
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DinnerGroupProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Chingu - 6人晚餐社交',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            theme: themeController.theme,
            home: const AuthGate(),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
