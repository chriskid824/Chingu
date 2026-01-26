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

  // 初始化日期格式化
  await initializeDateFormatting('zh_TW', null);

  // 初始化通知並處理啟動邏輯
  List<RouteSettings> initialRoutes = [];
  try {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      final data = initialMessage.data;
      final actionType = data['actionType'];
      final actionData = data['actionData'];

      if (actionType == 'open_chat') {
        initialRoutes.add(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: {'initialIndex': 3},
          ),
        );

        // 嘗試獲取目標用戶 ID 或聊天室 ID
        final userId = data['userId'] ?? actionData;
        final chatRoomId = data['chatRoomId'];

        if (userId != null || chatRoomId != null) {
          initialRoutes.add(
            RouteSettings(
              name: AppRoutes.chatDetail,
              arguments: {
                'userId': userId,
                'chatRoomId': chatRoomId,
              },
            ),
          );
        }
      } else if (actionType == 'view_event') {
        initialRoutes.add(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
          ),
        );
        initialRoutes.add(
          const RouteSettings(
            name: AppRoutes.eventDetail,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Error handling initial notification: $e');
  }

  // 初始化豐富通知服務
  await RichNotificationService().initialize();

  runApp(ChinguApp(initialRoutes: initialRoutes));
}

class ChinguApp extends StatelessWidget {
  final List<RouteSettings>? initialRoutes;

  const ChinguApp({
    super.key,
    this.initialRoutes,
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
            initialRoute: (initialRoutes == null || initialRoutes!.isEmpty)
                ? AppRoutes.mainNavigation
                : null,
            onGenerateInitialRoutes: (initialRoutes != null && initialRoutes!.isNotEmpty)
                ? (_) {
                    return initialRoutes!.map((settings) {
                      return AppRouter.generateRoute(settings);
                    }).toList();
                  }
                : null,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
