import 'package:flutter/material.dart';

/// 極簡風格配色系統
/// 靈感來源: Dribbble Smart Fitness App - Minimal Health Dashboard (Dark Mode)
/// 特點: 深灰/黑色系背景、靛藍紫色系強調色、柔和陰影
class AppColorsMinimal {
  // ==================== 主色系 ====================
  
  /// 主色 - 清新淺紫藍 (保持高對比度)
  static const Color primary = Color(0xFF8B9FFF);  // 淺紫藍
  
  /// 主色 - 淺色變體
  static const Color primaryLight = Color(0xFFB4C5FF);  // 更淺
  
  /// 主色 - 深色變體
  static const Color primaryDark = Color(0xFF6B7FE8);  // 柔和深色
  
  /// 主色 - 極淺背景 (用於深色模式下的強調背景，需降低透明度)
  static const Color primaryBackground = Color(0xFF1E2030);  // 深藍紫背景
  
  // ==================== 次要色系 ====================
  
  /// 次要色 - 清新薰衣草紫
  static const Color secondary = Color(0xFFB8A8FF);  // 淺薰衣草
  
  /// 次要色 - 淺色變體
  static const Color secondaryLight = Color(0xFFD4C8FF);  // 更淺
  
  /// 次要色 - 深色變體
  static const Color secondaryDark = Color(0xFF9B8AE8);  // 柔和深色
  
  // ==================== 背景色系 (Light Mode) ====================
  
  /// 主背景 - 純白
  static const Color background = Color(0xFFFFFFFF);  // 純白
  
  /// 表面色 - 淺灰白（用於卡片）
  static const Color surface = Color(0xFFFAFAFA);  // 淺灰白
  
  /// 表面色變體 - 略深的淺灰（用於分隔線、邊框、輸入框背景）
  static const Color surfaceVariant = Color(0xFFF5F5F7);  // 略深淺灰
  
  /// 表面色 - 禁用狀態
  static const Color surfaceDisabled = Color(0xFFE0E0E0);
  
  // ==================== 文字色系 (Light Mode) ====================
  
  /// 主要文字 - 深灰黑
  static const Color textPrimary = Color(0xFF1A1A1A);
  
  /// 次要文字 - 中灰
  static const Color textSecondary = Color(0xFF6B6B6B);
  
  /// 輔助文字 - 淺灰
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  /// 禁用文字
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  /// 反色文字 - 白色（用於深色按鈕/背景）
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // ==================== 功能色系 ====================
  
  /// 成功色 - 清新綠
  static const Color success = Color(0xFF06A77D);
  
  /// 成功色 - 淺色背景
  static const Color successLight = Color(0xFFE6F7F3);
  
  /// 警告色 - 暖黃
  static const Color warning = Color(0xFFF4D35E);
  
  /// 警告色 - 淺色背景
  static const Color warningLight = Color(0xFFFEF8E6);
  
  /// 錯誤色 - 柔和紅
  static const Color error = Color(0xFFEF476F);
  
  /// 錯誤色 - 淺色背景
  static const Color errorLight = Color(0xFFFEE9EE);
  
  /// 資訊色 - 藍色
  static const Color info = Color(0xFF3B82F6);
  
  /// 資訊色 - 淺色背景
  static const Color infoLight = Color(0xFFE7F2FE);
  
  // ==================== 陰影色系 (Light Mode) ====================
  
  /// 極淺陰影
  static const Color shadowLight = Color(0x0A000000);  // black with 0.04 opacity
  
  /// 淺陰影
  static const Color shadowMedium = Color(0x14000000);  // black with 0.08 opacity
  
  /// 中等陰影
  static const Color shadowDark = Color(0x1F000000);  // black with 0.12 opacity
  
  // ==================== 分隔線 ====================
  
  /// 分隔線顏色
  static const Color divider = Color(0xFF2C2C2E); // 與 surfaceVariant 接近
  
  /// 邊框顏色
  static const Color border = Color(0xFF3F3F46);
  
  // ==================== 漸層色 ====================
  
  /// 主色漸層 (清新淺紫藍到薰衣草)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B9FFF), // 淺紫藍
      Color(0xFFB8A8FF), // 淺薰衣草
    ],
  );
  
  /// 透明漸層 (用於卡片、背景) - 調整為適應深色
  static const LinearGradient transparentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x208B9FFF), // 淺紫藍 20% 透明
      Color(0x10B8A8FF), // 淺薰衣草 10% 透明
    ],
  );
  
  /// 次要漸層 (薰衣草到粉紫)
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB8A8FF), // 淺薰衣草
      Color(0xFFE0C8FF), // 淺粉紫
    ],
  );
  
  /// 玻璃質感漸層 (深色毛玻璃)
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30FFFFFF), // 注意：深色模式下的玻璃感通常需要亮色反光或深色底
      Color(0x05FFFFFF), 
    ],
  );
  
  /// 成功漸層 (清新綠)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6EE7B7), // 淺綠
      Color(0xFF34D399), // 中綠
    ],
  );
  
  // ==================== 特殊用途色 ====================
  
  /// 覆蓋層背景
  static Color overlay = Colors.black.withOpacity(0.7);
  
  /// 輕微覆蓋層
  static Color overlayLight = Colors.black.withOpacity(0.4);
  
  /// Shimmer 效果基礎色 (深色)
  static const Color shimmerBase = Color(0xFF2C2C2E);
  
  /// Shimmer 效果高亮色 (深色)
  static const Color shimmerHighlight = Color(0xFF3F3F46);
}

