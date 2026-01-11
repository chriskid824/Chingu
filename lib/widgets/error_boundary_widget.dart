import 'package:flutter/material.dart';
import 'package:chingu/widgets/error_screen.dart';

/// 全局錯誤邊界元件
///
/// 用於替代 Flutter 預設的紅色錯誤畫面 (ErrorWidget)
class ErrorBoundaryWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  final bool isDev;

  const ErrorBoundaryWidget({
    super.key,
    required this.errorDetails,
    this.isDev = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorScreen(
      title: '哎呀，出錯了',
      message: '應用程式遇到無法預期的錯誤。我們已記錄此問題並將盡快修復。',
      errorDetails: errorDetails,
      retryLabel: '重新載入應用程式',
      onRetry: () {
        // Since this is a build error, "retry" might effectively mean reloading the app
        // strictly speaking, we can't easily "retry" a specific widget rebuild failure
        // without re-rendering the whole tree or the parent.
        // For now, we might just try to trigger a rebuild or reload.
        // However, hot reload (in dev) works automatically.
        // In release, this might require a full app restart or navigation reset.

        // Try to pop to root
        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
           navigator.pop();
        }
      },
    );
  }
}
