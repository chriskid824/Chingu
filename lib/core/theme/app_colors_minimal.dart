import 'package:flutter/material.dart';

/// Chingu Design Token System — 小清新 · 天空藍 + 薄荷綠
/// 
/// 設計原則：
/// - 清新、療癒、像看天空的感覺
/// - 微藍白底 + 天空藍漸層 + 薄荷綠點綴
/// - 大圓角、充分留白、柔和藍灰陰影
/// - 靈感：Apple Health App、晴朗天空、薄荷微風
class AppColorsMinimal {
  // ==================== 主色系（天空藍） ====================
  
  /// 主色 - 天空藍
  static const Color primary = Color(0xFF64B5F6);
  
  /// 主色 - 淺色變體
  static const Color primaryLight = Color(0xFF90CAF9);
  
  /// 主色 - 深色變體
  static const Color primaryDark = Color(0xFF1E88E5);
  
  /// 主色 - 極淺背景（提示條、Tag 背景）
  static const Color primaryBackground = Color(0xFFE3F2FD);
  
  // ==================== 次要色系（薄荷綠） ====================
  
  /// 次要色 - 薄荷綠
  static const Color secondary = Color(0xFF80CBC4);
  
  /// 次要色 - 淺色變體
  static const Color secondaryLight = Color(0xFFB2DFDB);
  
  /// 次要色 - 深色變體
  static const Color secondaryDark = Color(0xFF4DB6AC);
  
  // ==================== 背景色系 ====================
  
  /// 主背景 - 微藍白（非純白，帶一絲天空感）
  static const Color background = Color(0xFFFAFCFF);
  
  /// 表面色 - 暖藍白（卡片用）
  static const Color surface = Color(0xFFF5F8FC);
  
  /// 表面色變體 - 淺藍灰（分隔線、邊框、輸入框）
  static const Color surfaceVariant = Color(0xFFECF0F6);
  
  /// 表面色 - 禁用狀態
  static const Color surfaceDisabled = Color(0xFFDEE4EA);
  
  // ==================== 文字色系 ====================
  
  /// 主要文字 - 深藍灰
  static const Color textPrimary = Color(0xFF263238);
  
  /// 次要文字 - 中藍灰
  static const Color textSecondary = Color(0xFF607D8B);
  
  /// 輔助文字 - 淺藍灰
  static const Color textTertiary = Color(0xFF90A4AE);
  
  /// 禁用文字
  static const Color textDisabled = Color(0xFFB0BEC5);
  
  /// 反色文字
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // ==================== 功能色系 ====================
  
  /// 成功色 - 薄荷綠
  static const Color success = Color(0xFF66BB6A);
  
  /// 成功色 - 淺色背景
  static const Color successLight = Color(0xFFE8F5E9);
  
  /// 警告色 - 柔和琥珀
  static const Color warning = Color(0xFFFFB74D);
  
  /// 警告色 - 淺色背景
  static const Color warningLight = Color(0xFFFFF8E1);
  
  /// 錯誤色 - 柔和紅
  static const Color error = Color(0xFFEF5350);
  
  /// 錯誤色 - 淺色背景
  static const Color errorLight = Color(0xFFFFEBEE);
  
  /// 資訊色 - 天空藍（與 primary 同色系）
  static const Color info = Color(0xFF42A5F5);
  
  /// 資訊色 - 淺色背景
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // ==================== 陰影色系（藍灰調） ====================
  
  /// 極淺陰影
  static const Color shadowLight = Color(0x0A78909C);
  
  /// 淺陰影
  static const Color shadowMedium = Color(0x1478909C);
  
  /// 中等陰影
  static const Color shadowDark = Color(0x1F78909C);
  
  // ==================== 分隔線 ====================
  
  /// 分隔線顏色
  static const Color divider = Color(0xFFDCE4EC);
  
  /// 邊框顏色
  static const Color border = Color(0xFFCFD8DC);
  
  // ==================== 漸層色 ====================
  
  /// 主色漸層（天空藍 → 薄荷綠，清新天空感）
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF64B5F6), // 天空藍
      Color(0xFF80CBC4), // 薄荷綠
    ],
  );
  
  /// 透明漸層（輕透天空藍，用於卡片背景）
  static const LinearGradient transparentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1864B5F6), // 天空藍 ~10%
      Color(0x0C80CBC4), // 薄荷綠 ~5%
    ],
  );
  
  /// 次要漸層（薄荷綠 → 淡薄荷）
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF80CBC4), // 薄荷綠
      Color(0xFFB2DFDB), // 淡薄荷
    ],
  );
  
  /// 玻璃質感漸層
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30FFFFFF),
      Color(0x08FFFFFF),
    ],
  );
  
  /// 成功漸層（柔和綠）
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA5D6A7), // 淺綠
      Color(0xFF66BB6A), // 柔和綠
    ],
  );
  
  // ==================== 特殊用途色 ====================
  
  /// 覆蓋層背景
  static Color overlay = const Color(0xB3263238); // 深藍灰 70%
  
  /// 輕微覆蓋層
  static Color overlayLight = const Color(0x66263238); // 深藍灰 40%
  
  /// Shimmer 效果基礎色
  static const Color shimmerBase = Color(0xFFECF0F6);
  
  /// Shimmer 效果高亮色
  static const Color shimmerHighlight = Color(0xFFF5F8FC);

  // ==================== 間距 Token ====================
  
  /// 4px
  static const double spaceXS = 4;
  /// 8px
  static const double spaceSM = 8;
  /// 12px
  static const double spaceMD = 12;
  /// 16px
  static const double spaceLG = 16;
  /// 24px
  static const double spaceXL = 24;
  /// 32px
  static const double space2XL = 32;
  /// 48px
  static const double space3XL = 48;

  // ==================== 圓角 Token ====================
  
  /// 小圓角（Chip、Tag）
  static const double radiusSM = 8;
  /// 中圓角（卡片、輸入框）
  static const double radiusMD = 16;
  /// 大圓角（主卡片、底部 Sheet）
  static const double radiusLG = 24;
  /// 全圓（頭像、進度環）
  static const double radiusFull = 999;
}
