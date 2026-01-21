import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/gradient_button.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  const TwoFactorVerificationScreen({super.key});

  @override
  State<TwoFactorVerificationScreen> createState() => _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState extends State<TwoFactorVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isResendDisabled = true;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 初始發送驗證碼
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendCode();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isResendDisabled = true;
      _resendTimer = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 0) {
        setState(() {
          _isResendDisabled = false;
        });
        timer.cancel();
      } else {
        setState(() {
          _resendTimer--;
        });
      }
    });
  }

  Future<void> _sendCode() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.sendTwoFactorCode();
    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('驗證碼已發送 (請查看控制台模擬輸出)')),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入6位數驗證碼')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyTwoFactor(code);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('雙因素驗證'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.security_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              '請輸入驗證碼',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '為了保護您的帳號安全，我們已發送驗證碼至您的信箱/手機',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            if (authProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            GradientButton(
              text: authProvider.isLoading ? '驗證中...' : '驗證',
              onPressed: authProvider.isLoading ? () {} : _verifyCode,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isResendDisabled ? null : _sendCode,
              child: Text(
                _isResendDisabled
                  ? '重新發送 ($_resendTimer)'
                  : '重新發送驗證碼',
                style: TextStyle(
                  color: _isResendDisabled ? Colors.grey : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
