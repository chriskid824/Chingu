import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/admin_groups_provider.dart';
import 'providers/admin_restaurants_provider.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_shell.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminGroupsProvider()),
        ChangeNotifierProvider(create: (_) => AdminRestaurantsProvider()),
      ],
      child: MaterialApp(
        title: 'Chingu 營運後台',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E5364)),
          useMaterial3: true,
          fontFamily: 'NotoSansTC',
        ),
        home: const _AdminAuthGate(),
      ),
    );
  }
}

class _AdminAuthGate extends StatelessWidget {
  const _AdminAuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedInAsAdmin) return const AdminShell();
        return const AdminLoginScreen();
      },
    );
  }
}
