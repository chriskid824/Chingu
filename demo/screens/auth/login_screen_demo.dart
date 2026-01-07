import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class LoginScreenDemo extends StatelessWidget {
  const LoginScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Logo 帶裝飾
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景光暈
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Logo 容器
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: chinguTheme?.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
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
              
              // 標題
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
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Email 輸入框
              TextFormField(
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 密碼輸入框
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密碼',
                  hintText: '••••••••',
                  prefixIcon: Icon(
                    Icons.lock_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                  suffixIcon: Icon(
                    Icons.visibility_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 忘記密碼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    '忘記密碼？',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 登入按鈕
              GradientButton(
                text: '登入',
                onPressed: () {},
                gradient: chinguTheme?.primaryGradient,
              ),
              
              const SizedBox(height: 24),
              
              // 分隔線
              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerTheme.color)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '或',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerTheme.color)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google 登入按鈕
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: chinguTheme?.surfaceVariant ?? Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '使用 Google 登入',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 註冊連結
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '還沒有帳號？',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  TextButton(
                    onPressed: () {},
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
    );
  }
}
