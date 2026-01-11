import 'package:flutter/material.dart';
import 'package:chingu/widgets/gradient_button.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool isFatal;
  final FlutterErrorDetails? errorDetails;

  const ErrorScreen({
    super.key,
    this.title = '發生了一點錯誤',
    this.message = '我們遇到了一些問題，請稍後再試。',
    this.onRetry,
    this.retryLabel = '重試',
    this.isFatal = false,
    this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebug = _isDebugMode();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),

              // Debug Info (only in debug mode)
              if (isDebug && errorDetails != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
                    ),
                  ),
                  height: 150,
                  child: SingleChildScrollView(
                    child: Text(
                      errorDetails!.exceptionAsString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Action Button
              if (onRetry != null)
                GradientButton(
                  text: retryLabel,
                  onPressed: onRetry!,
                  width: double.infinity,
                )
              else
                GradientButton(
                  text: '返回首頁',
                  onPressed: () {
                    // Try to navigate to home, but if router is broken, might fail
                     Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  width: double.infinity,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDebugMode() {
    bool debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }
}
