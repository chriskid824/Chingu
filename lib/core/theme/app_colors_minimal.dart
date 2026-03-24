import 'package:flutter/material.dart';

/// Chingu Design Token System — 莫蘭迪暖色系 (Morandi Warm)
/// 
/// 設計原則：
/// - 內斂、質感、高雅
/// - 淺藍灰底色 + 磚橘/深棕點綴 (溫暖與獨特)
/// - 大圓角、柔和陰影、卡片式留白
class AppColorsMinimal {
  // ==================== 主色系（天空藍灰） ====================
  
  /// 主色 - 深莫蘭迪藍灰 (標題文字, Segment 選取字)
  static const Color primary = Color(0xFF2E5364);
  
  /// 主色 - 淺色背景 (Segment 底色, SearchBar 底板)
  static const Color primaryBackground = Color(0xFFEAEFF3);
  
  // ==================== 次要色系（磚橘/深棕色Accent） ====================
  
  /// 次要色 - 磚橘色 (Badge, 點綴)
  static const Color secondary = Color(0xFFA64A25);
  
  /// FAB 色調
  static const Color fabStart = Color(0xFFD67756);
  static const Color fabEnd = Color(0xFFE9967A);

  // ==================== 背景色系 ====================
  
  /// 主背景 - 極淺灰藍
  static const Color background = Color(0xFFF7F9FB);
  
  /// 表面色 - 卡片純白
  static const Color surface = Color(0xFFFFFFFF);
  
  /// 表面變體 - 特殊區塊底板
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  
  // ==================== 文字色系 ====================
  
  /// 主要文字 - 深灰黑
  static const Color textPrimary = Color(0xFF1A1A1A);
  
  /// 次要文字 - 灰
  static const Color textSecondary = Color(0xFF757575);
  
  // ==================== 狀態色系 ====================
  
  static const Color success = Color(0xFF4CAF50);    // 上線綠點
  static const Color warning = Color(0xFF885520);    // 在線褐點
  static const Color error = Color(0xFFEF5350);      // 刪除、警告
  static const Color info = Color(0xFF6B93B8);       // 漸層起點
  
  // ==================== 陰影色系 ====================
  
  static const Color shadowLight = Color(0x08000000);   // 極輕柔黑
  static const Color shadowMedium = Color(0x14000000);  // 輕柔黑
  
  // ==================== 漸層 Token ====================
  
  /// AppBar 標題漸層 (莫蘭迪藍)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF6B93B8), 
      Color(0xFF8DB6C9),
    ],
  );
  
  /// FAB 懸浮按鈕漸層 (蜜桃橘棕)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD67756),
      Color(0xFFE9967A),
    ],
  );
  
  /// 原有的玻璃效應
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x30FFFFFF), Color(0x08FFFFFF)],
  );

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

  // ==================== 舊版相容與遺留 Token ====================
  static const Color primaryLight = Color(0xFF90CAF9);
  static const Color primaryDark = Color(0xFF1E88E5);
  static const Color secondaryLight = Color(0xFFB2DFDB);
  static const Color secondaryDark = Color(0xFF4DB6AC);
  static const Color surfaceDisabled = Color(0xFFDEE4EA);
  static const Color textTertiary = Color(0xFF90A4AE);
  static const Color textDisabled = Color(0xFFB0BEC5);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color shadowDark = Color(0x1F78909C);
  static const Color divider = Color(0xFFDCE4EC);
  static const Color border = Color(0xFFCFD8DC);
  static const LinearGradient transparentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1864B5F6), Color(0x0C80CBC4)],
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF80CBC4), Color(0xFFB2DFDB)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
  );
  static Color overlay = const Color(0xB3263238);
  static Color overlayLight = const Color(0x66263238);
  static const Color shimmerBase = Color(0xFFECF0F6);
  static const Color shimmerHighlight = Color(0xFFF5F8FC);
}
