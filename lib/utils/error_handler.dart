import 'package:flutter/material.dart';

class ErrorHandler {
  /// 通用錯誤處理方法
  ///
  /// [context] BuildContext 用於顯示 SnackBar
  /// [error] 錯誤物件
  /// [stackTrace] 堆疊追蹤（可選）
  /// [onRetry] 重試回調函數（可選）
  static void handleError(BuildContext context, dynamic error, {StackTrace? stackTrace, VoidCallback? onRetry}) {
    // 這裡可以加入日誌記錄邏輯
    debugPrint('發生錯誤: $error');
    if (stackTrace != null) {
      debugPrint('堆疊追蹤: $stackTrace');
    }

    String message = _getErrorMessage(error);
    showErrorSnackBar(context, message, onRetry: onRetry);
  }

  /// 顯示錯誤 SnackBar
  ///
  /// [onRetry] 若提供，SnackBar 的按鈕將變為「重試」
  static void showErrorSnackBar(BuildContext context, String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: onRetry != null ? '重試' : '關閉',
          textColor: Colors.white,
          onPressed: () {
            if (onRetry != null) {
              onRetry();
            }
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 解析錯誤訊息
  static String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      // 去掉 "Exception: " 前綴
      return error.toString().replaceAll('Exception: ', '');
    }
    // 如果是 Error 物件 (如 AssertionError)
    if (error is Error) {
      return '發生系統錯誤: ${error.toString()}';
    }
    return error.toString();
  }
}
