import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  final String verificationId; // Not used currently, but kept for interface compatibility
  final String target; // Email or Phone

  const TwoFactorVerificationScreen({
    super.key,
    required this.verificationId,
    required this.target,
  });

  @override
  State<TwoFactorVerificationScreen> createState() => _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState extends State<TwoFactorVerificationScreen> {
  final _twoFactorAuthService = TwoFactorAuthService();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text;
    if (code.length != 6) {
      setState(() => _errorMessage = '請輸入 6 位數驗證碼');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _twoFactorAuthService.verifyCode(widget.target, code);

      if (!mounted) return;

      if (isValid) {
        if (mounted) {
           context.read<AuthProvider>().verifyTwoFactor();
        }
        // Verification successful, proceed to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mainNavigation,
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = '驗證碼錯誤或已過期';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine method based on target (simple heuristic)
      final method = widget.target.contains('@') ? 'email' : 'sms';

      await _twoFactorAuthService.sendVerificationCode(
        target: widget.target,
        method: method,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('驗證碼已重新發送')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '重新發送失敗: $e');
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
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                '雙因素認證',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                '為了保護您的帳號安全，請輸入發送至\n${widget.target} 的驗證碼',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Code Input
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 24),

              GradientButton(
                text: _isLoading ? '驗證中...' : '驗證',
                onPressed: _isLoading ? () {} : _handleVerify,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '沒收到驗證碼？',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: Text(
                      '重新發送',
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
    );
  }
}
