import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/providers/auth_provider.dart';
import '../../core/routes/app_router.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'test@gmail.com');
  final _passwordController = TextEditingController(text: '111111');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final userDoc = await FirestoreService().getUser(user.uid);
          if (userDoc != null && userDoc.isTwoFactorEnabled) {
            final method = userDoc.twoFactorMethod;
            final target = method == 'sms'
                ? (userDoc.phoneNumber ?? '')
                : userDoc.email;

            if (target.isEmpty) {
               throw Exception('開啟了雙因素認證但缺少聯絡資訊');
            }

            await TwoFactorAuthService().sendVerificationCode(
              target: target,
              method: method,
              uid: user.uid,
            );

            if (!mounted) return;

            Navigator.pushReplacementNamed(
              context,
              AppRoutes.otpVerification,
              arguments: {
                'target': target,
                'method': method,
                'uid': user.uid,
              },
            );
            return;
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('驗證檢查失敗: $e'),
              backgroundColor: Colors.red,
            ),
          );
          // 登出以避免卡在已登入但未驗證的狀態
          await authProvider.signOut();
          return;
        }
      }
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '登入失敗，請稍後再試'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google 登入失敗'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Logo 帶裝飾
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 背景光暈
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Logo 容器
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 標題
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '歡迎回來',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('👋', style: TextStyle(fontSize: 32)),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '登入以繼續您的晚餐之旅',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Email 輸入框
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '電子郵件',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(
                      Icons.email_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入電子郵件';
                    }
                    if (!value.contains('@')) {
                      return '請輸入有效的電子郵件';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 密碼輸入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '密碼',
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入密碼';
                    }
                    if (value.length < 6) {
                      return '密碼長度至少需要 6 個字元';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // 忘記密碼
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(
                      '忘記密碼？',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 登入按鈕
                GradientButton(
                  text: _isLoading ? '登入中...' : '登入',
                  onPressed: _isLoading ? () {} : _handleLogin,
                ),

                // 暫時的開發者工具入口
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.bug_report, color: Colors.grey),
                  label: const Text('開發者工具 (生成假數據)', style: TextStyle(color: Colors.grey)),
                  onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.debug),
                ),
                
                const SizedBox(height: 24),
                
                // 分隔線
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '或',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Google 登入按鈕
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: chinguTheme?.surfaceVariant ?? Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '使用 Google 登入',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 註冊連結
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '還沒有帳號？',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                      child: Text(
                        '立即註冊',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
