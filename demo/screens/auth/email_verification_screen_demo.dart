import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class EmailVerificationScreenDemo extends StatelessWidget {
  const EmailVerificationScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 郵件圖標插圖
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: AppColorsMinimal.transparentGradient,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColorsMinimal.primaryBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    size: 60,
                    color: AppColorsMinimal.primary,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColorsMinimal.successGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColorsMinimal.success.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 標題
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '驗證您的電子郵件',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('📧', style: TextStyle(fontSize: 26)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '我們已發送驗證郵件至',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Email 地址
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.transparentGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsMinimal.primaryLight.withOpacity(0.3),
                ),
              ),
              child: const Text(
                'user@example.com',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorsMinimal.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '請檢查您的收件匣並點擊驗證連結',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColorsMinimal.textTertiary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 開啟郵件按鈕
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      '開啟郵件應用程式',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 重新發送
            TextButton(
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColorsMinimal.secondary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '沒有收到郵件？重新發送',
                    style: TextStyle(
                      color: AppColorsMinimal.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 稍後再說
            TextButton(
              onPressed: () {},
              child: const Text(
                '稍後再說',
                style: TextStyle(
                  color: AppColorsMinimal.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
