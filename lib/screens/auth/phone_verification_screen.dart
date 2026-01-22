import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chingu/services/phone_auth_service.dart';
import 'package:chingu/widgets/otp_input.dart';
import 'package:chingu/widgets/gradient_button.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入手機號碼')));
       return;
    }
    // Simple E.164 format check/append
    // Assuming user inputs local format like 0912345678 -> +886912345678 for Taiwan
    // Or just require full format. Let's assume +886...

    setState(() => _isLoading = true);

    await _phoneAuthService.sendOTP(
      phoneNumber: phone,
      onCodeSent: (id) {
        if (mounted) {
           setState(() {
             _codeSent = true;
             _isLoading = false;
           });
           _startTimer();
        }
      },
      onError: (msg) {
        if (mounted) {
           setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    );
  }

  Future<void> _verifyCode() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    try {
      await _phoneAuthService.verifyOTP(otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('驗證成功！')));
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手機驗證')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '為了確保帳戶安全與真實性，請驗證您的手機號碼。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (!_codeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手機號碼 (例如 +886912345678)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: '發送驗證碼',
                onPressed: _isLoading ? null : _sendCode,
                isLoading: _isLoading,
              ),
            ] else ...[
              Text(
                '驗證碼已發送至 ${_phoneController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SimpleOtpInput(
                controller: _otpController,
                length: 6,
                onCompleted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: '驗證',
                onPressed: _isLoading ? null : _verifyCode,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendCountdown == 0 ? _sendCode : null,
                child: Text(_resendCountdown == 0
                  ? '重新發送驗證碼'
                  : '重新發送 ($_resendCountdown)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
