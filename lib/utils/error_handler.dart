import 'package:flutter/material.dart';
import 'package:chingu/services/crash_reporting_service.dart';

class ErrorHandler {
  /// 通用錯誤處理方法
  ///
  /// [context] BuildContext 用於顯示 SnackBar
  /// [error] 錯誤物件
  /// [stackTrace] 堆疊追蹤（可選）
  static void handleError(BuildContext context, dynamic error, {StackTrace? stackTrace}) {
    // 記錄錯誤到 Crashlytics
    try {
      CrashReportingService().recordError(error, stackTrace, reason: 'ErrorHandler.handleError');
    } catch (e) {
      debugPrint('CrashReportingService failed: $e');
    }

    // 這裡可以加入日誌記錄邏輯
    debugPrint('發生錯誤: $error');
    if (stackTrace != null) {
      debugPrint('堆疊追蹤: $stackTrace');
    }

    String message = _getErrorMessage(error);
    showErrorSnackBar(context, message);
  }

  /// 顯示錯誤 SnackBar
  static void showErrorSnackBar(BuildContext context, String message) {
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
          label: '關閉',
          textColor: Colors.white,
          onPressed: () {
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
