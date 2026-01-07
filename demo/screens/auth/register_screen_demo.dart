import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class RegisterScreenDemo extends StatelessWidget {
  const RegisterScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題
              Row(
                children: [
                  const Text(
                    '建立帳號',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 32)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '開始您的美食社交之旅',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColorsMinimal.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Email
              TextFormField(
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: AppColorsMinimal.primary,
                  ),
                  filled: true,
                  fillColor: AppColorsMinimal.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 密碼
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密碼',
                  hintText: '至少 8 個字元',
                  prefixIcon: Icon(
                    Icons.lock_rounded,
                    color: AppColorsMinimal.secondary,
                  ),
                  suffixIcon: Icon(
                    Icons.visibility_rounded,
                    color: AppColorsMinimal.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColorsMinimal.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.secondary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 確認密碼
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '確認密碼',
                  hintText: '再次輸入密碼',
                  prefixIcon: Icon(
                    Icons.lock_rounded,
                    color: AppColorsMinimal.success,
                  ),
                  suffixIcon: Icon(
                    Icons.check_circle_rounded,
                    color: AppColorsMinimal.success,
                  ),
                  filled: true,
                  fillColor: AppColorsMinimal.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorsMinimal.success, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 條款同意
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.transparentGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColorsMinimal.primaryLight.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '我同意 服務條款 和 隱私政策',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColorsMinimal.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 註冊按鈕
              Container(
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColorsMinimal.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '註冊',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Google 註冊
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColorsMinimal.surfaceVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: AppColorsMinimal.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '使用 Google 註冊',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
