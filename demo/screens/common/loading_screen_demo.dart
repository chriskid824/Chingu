import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class LoadingScreenDemo extends StatelessWidget {
  const LoadingScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColorsMinimal.transparentGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColorsMinimal.primary),
                  strokeWidth: 4,
                  backgroundColor: AppColorsMinimal.surfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '載入中...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColorsMinimal.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





