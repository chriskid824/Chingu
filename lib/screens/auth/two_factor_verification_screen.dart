import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  const TwoFactorVerificationScreen({super.key});

  @override
  State<TwoFactorVerificationScreen> createState() => _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState extends State<TwoFactorVerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resendCode();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    // 如果是從 Settings 進來（可能沒有自動發送），這裡假設用戶已經請求了代碼。
    // 但是這頁面通常是登入流程。

    final success = await authProvider.verifyTwoFactor(_codeController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '驗證失敗，請重試'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final demoCode = await context.read<AuthProvider>().requestTwoFactorCode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('驗證碼已發送${demoCode != null ? " (Demo: $demoCode)" : ""}')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = context.select((AuthProvider p) => p.userModel);
    final method = userModel?.twoFactorMethod == 'sms' ? '簡訊' : '電子郵件';

    return Scaffold(
      appBar: AppBar(
        title: const Text('二階段驗證'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            // 如果是用戶登出或放棄登入
            context.read<AuthProvider>().signOut();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.security_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '驗證您的身分',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '我們已發送驗證碼至您的$method，請輸入該驗證碼以繼續。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return '請輸入 6 位數驗證碼';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: _isLoading ? '驗證中...' : '驗證',
                onPressed: _isLoading ? () {} : _verifyCode,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _resendCode,
                child: Text('沒收到？重新發送驗證碼'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
