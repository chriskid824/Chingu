import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/providers/auth_provider.dart';
import '../../core/routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // 正式版不預填帳密
  final _emailController = TextEditingController(
    text: kDebugMode ? 'test@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? '111111' : '',
  );
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    debugPrint('📧 Email 登入按鈕被點擊');
    if (!_formKey.currentState!.validate()) {
      debugPrint('📧 表單驗證失敗');
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!success) {
        setState(() {
          _loginError = authProvider.errorMessage ?? '登入失敗，請檢查帳號密碼';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginError = '登入發生錯誤，請稍後再試';
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    debugPrint('🔵 Google 登入按鈕被點擊');
    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!success) {
        final errorMsg = authProvider.errorMessage ?? 'Google 登入失敗';
        debugPrint('🔴 Google 登入失敗: $errorMsg');
        setState(() {
          _loginError = errorMsg;
        });
      }
    } catch (e) {
      debugPrint('🔴 Google 登入異常: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginError = 'Google 登入發生錯誤: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithApple();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!success) {
        setState(() {
          _loginError = authProvider.errorMessage ?? 'Apple 登入失敗，請稍後再試';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loginError = 'Apple 登入發生錯誤，請稍後再試';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColorsMinimal.primaryBackground,
              AppColorsMinimal.background,
              AppColorsMinimal.surface,
            ],
            stops: const [0.0, 0.35, 0.6],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppColorsMinimal.spaceSM),

                // Mascot
                Center(
                  child: Image.asset(
                    'assets/images/login_mascot.png',
                    width: 240,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppColorsMinimal.spaceXL),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '歡迎回來',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppColorsMinimal.spaceSM),

                Text(
                  '登入以繼續您的晚餐之旅',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColorsMinimal.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppColorsMinimal.space2XL),

                // ===== Social Login =====
                _buildAppleButton(),
                const SizedBox(height: AppColorsMinimal.spaceMD),
                _buildGoogleButton(),

                const SizedBox(height: AppColorsMinimal.spaceXL),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColorsMinimal.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceLG),
                      child: Text(
                        '或使用電子郵件',
                        style: TextStyle(
                          color: AppColorsMinimal.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColorsMinimal.border)),
                  ],
                ),

                const SizedBox(height: AppColorsMinimal.spaceXL),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '電子郵件',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(
                      Icons.email_rounded,
                      color: AppColorsMinimal.textTertiary,
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

                const SizedBox(height: AppColorsMinimal.spaceLG),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: '密碼',
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_rounded,
                      color: AppColorsMinimal.textTertiary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: AppColorsMinimal.textTertiary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

                // 登入錯誤提示
                if (_loginError != null) ...[
                  const SizedBox(height: AppColorsMinimal.spaceMD),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceMD, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColorsMinimal.errorLight,
                      borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
                      border: Border.all(color: AppColorsMinimal.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColorsMinimal.error, size: 20),
                        const SizedBox(width: AppColorsMinimal.spaceSM),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: TextStyle(color: AppColorsMinimal.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppColorsMinimal.spaceSM),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(
                      '忘記密碼？',
                      style: TextStyle(color: AppColorsMinimal.textTertiary),
                    ),
                  ),
                ),

                const SizedBox(height: AppColorsMinimal.spaceXL),

                // Login button
                GradientButton(
                  text: _isLoading ? '登入中...' : '登入',
                  onPressed: _isLoading ? () {} : _handleLogin,
                ),

                const SizedBox(height: AppColorsMinimal.space2XL),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '還沒有帳號？',
                      style: TextStyle(color: AppColorsMinimal.textSecondary),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                      child: Text(
                        '立即註冊',
                        style: TextStyle(
                          color: AppColorsMinimal.primary,
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
      ),
    );
  }

  /// Apple 登入按鈕
  Widget _buildAppleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleAppleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColorsMinimal.surface,
          foregroundColor: AppColorsMinimal.textPrimary,
          elevation: 0,
          side: BorderSide(color: AppColorsMinimal.border),
          padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Icon(Icons.apple, size: 30, color: AppColorsMinimal.textPrimary),
            ),
            const SizedBox(width: AppColorsMinimal.spaceSM),
            Text(
              '使用 Apple 登入',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsMinimal.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  /// Google 登入按鈕
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColorsMinimal.surface,
          foregroundColor: AppColorsMinimal.textPrimary,
          elevation: 0,
          side: BorderSide(color: AppColorsMinimal.border),
          padding: const EdgeInsets.symmetric(horizontal: AppColorsMinimal.spaceLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            Text(
              '使用 Google 登入',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
