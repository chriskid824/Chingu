import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
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
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithGoogle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Google 登入失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入發生錯誤: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Apple 登入失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apple 登入發生錯誤: $e'),
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
                
                // Logo
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                
                // Title
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),

                // ===== Social Login =====
                // Apple Sign-In
                _buildAppleButton(),
                const SizedBox(height: 12),

                // Google Sign-In
                _buildGoogleButton(theme, chinguTheme),

                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '或使用電子郵件',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
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
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                
                // 登入錯誤提示
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                
                // Forgot password
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
                
                // Login button
                GradientButton(
                  text: _isLoading ? '登入中...' : '登入',
                  onPressed: _isLoading ? () {} : _handleLogin,
                ),


                
                const SizedBox(height: 32),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '還沒有帳號？',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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

  /// Apple 登入按鈕
  Widget _buildAppleButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAppleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Icon(Icons.apple, size: 30),
            ),
            const SizedBox(width: 8),
            const Text(
              '使用 Apple 登入',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// Google 登入按鈕
  Widget _buildGoogleButton(ThemeData theme, ChinguTheme? chinguTheme) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: chinguTheme?.surfaceVariant ?? Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 官方彩色 logo
            Image.asset(
              'assets/images/google_logo.png',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 10),
            Text(
              '使用 Google 登入',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
