import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/screens/auth/login_screen.dart';
import 'package:chingu/screens/main_screen.dart';
import 'package:chingu/screens/profile/profile_setup_screen.dart';
import 'package:chingu/services/force_update_service.dart';

/// Auth Gate — 根據登入狀態和資料完成度自動分流
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // 背景檢查版本，不阻擋 UI
    _checkVersionInBackground();
  }

  Future<void> _checkVersionInBackground() async {
    try {
      final needsUpdate = await ForceUpdateService().checkForUpdate();
      if (needsUpdate && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ForceUpdateService.showUpdateDialog(context);
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ 版本檢查失敗: $e');
      // 失敗不阻擋
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (kDebugMode) {
          debugPrint('🔐 AuthGate status: ${authProvider.status}');
        }

        switch (authProvider.status) {
          case AuthStatus.uninitialized:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case AuthStatus.unauthenticated:
            return const LoginScreen();

          case AuthStatus.authenticated:
            final user = authProvider.userModel;

            if (user == null) {
              if (authProvider.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const ProfileSetupScreen();
            }

            if (!user.isProfileComplete) {
              if (kDebugMode) {
                debugPrint('🔐 AuthGate: 資料不完整 → Onboarding');
              }
              return const ProfileSetupScreen();
            }

            return const MainScreen();
        }
      },
    );
  }
}
