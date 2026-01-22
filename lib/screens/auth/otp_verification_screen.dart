import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String target;
  final String method;
  final String uid;

  const OtpVerificationScreen({
    super.key,
    required this.target,
    required this.method,
    required this.uid,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  final _twoFactorAuthService = TwoFactorAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = '請輸入 6 位數驗證碼';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _twoFactorAuthService.verifyCode(widget.target, code);
      if (isValid) {
        if (mounted) {
          context.read<AuthProvider>().setTwoFactorVerified(true);
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = '驗證碼錯誤或已過期';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      await _twoFactorAuthService.sendVerificationCode(
        target: widget.target,
        method: widget.method,
        uid: widget.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('驗證碼已重新發送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('驗證身分'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              '請輸入驗證碼',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '我們已發送 6 位數驗證碼至',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.target,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: _isLoading ? '驗證中...' : '驗證',
              onPressed: _isLoading ? () {} : _verifyCode,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: const Text('沒收到驗證碼？重新發送'),
            ),
          ],
        ),
      ),
    );
  }
}
