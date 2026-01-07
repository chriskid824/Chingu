import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class ForgotPasswordScreenDemo extends StatelessWidget {
  const ForgotPasswordScreenDemo({super.key});
  
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // 圖標插圖
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.transparentGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColorsMinimal.primaryLight.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 50,
                      color: AppColorsMinimal.primary,
                    ),
                    Positioned(
                      bottom: 25,
                      right: 25,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColorsMinimal.secondaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 標題
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '忘記密碼？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('🔑', style: TextStyle(fontSize: 28)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              '請輸入您的電子郵件地址\n我們將發送重設密碼的連結給您',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Email 輸入框
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
            
            const SizedBox(height: 24),
            
            // 發送按鈕
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      '發送重設連結',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 返回登入
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColorsMinimal.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '返回登入',
                    style: TextStyle(
                      color: AppColorsMinimal.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
