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

  // 初始化 Crashlytics
  await CrashReportingService().initialize();

  // 嘗試獲取初始通知（當 App 從終止狀態被點擊開啟時）
  RemoteMessage? initialMessage;
  try {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  } catch (e) {
    debugPrint('Error getting initial message: $e');
  }

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  runApp(ChinguApp(initialMessage: initialMessage));
}

class ChinguApp extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const ChinguApp({
    super.key,
    this.initialMessage,
  });

  @override
  State<ChinguApp> createState() => _ChinguAppState();
}

class _ChinguAppState extends State<ChinguApp> {
  @override
  void initState() {
    super.initState();
    _handleInitialMessage();
  }

  void _handleInitialMessage() {
    if (widget.initialMessage != null) {
      // 使用 addPostFrameCallback 確保 Navigator 已掛載
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 直接使用 RemoteMessage 的 data map
        RichNotificationService().handleNotificationData(widget.initialMessage!.data);
      });
    }
  }

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
          );
        },
      ),
    );
  }
}
