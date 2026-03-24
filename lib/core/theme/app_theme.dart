import 'package:flutter/material.dart';
import 'app_colors_minimal.dart';

enum AppThemePreset {
  orange,    // 既有主題（暖橘）
  minimal,   // 靜謐溫暖（莫蘭迪藍灰 + 磚橘）
  blue,      // 冷藍
  green,     // 清新綠
  purple,    // 高級紫
  pink,      // 活力粉
}

/// Custom Theme Extension for Chingu App
/// 透過 `Theme.of(context).extension<ChinguTheme>()` 存取精緻的 Design Tokens
class ChinguTheme extends ThemeExtension<ChinguTheme> {
  // 原有的漸層
  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;
  final LinearGradient glassGradient;
  final LinearGradient transparentGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient successGradient;
  
  // ==================== Semantic UI Tokens (擴充的 UI 語意變數) ====================
  /// 未讀訊息/提示的特別徽章色 (磚橘色系)
  final Color badgeColor;
  /// 懸浮動作按鈕 (FAB) 的主要漸層色
  final LinearGradient fabGradient;
  /// 頂部 AppBar 標題的專屬漸層色 (莫蘭迪藍灰)
  final LinearGradient appBarTitleGradient;
  /// 卡片標準陰影
  final List<BoxShadow> chatCardShadow;

  // 原有的基本色調
  final Color surfaceVariant;
  final Color shadowLight;
  final Color shadowMedium;
  final Color secondary;
  final Color info;
  final Color success;
  final Color warning;
  final Color error;

  const ChinguTheme({
    required this.primaryGradient,
    required this.accentGradient,
    required this.glassGradient,
    required this.transparentGradient,
    required this.secondaryGradient,
    required this.successGradient,
    required this.badgeColor,
    required this.fabGradient,
    required this.appBarTitleGradient,
    required this.chatCardShadow,
    required this.surfaceVariant,
    required this.shadowLight,
    required this.shadowMedium,
    required this.secondary,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
  });

  @override
  ThemeExtension<ChinguTheme> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? accentGradient,
    LinearGradient? glassGradient,
    LinearGradient? transparentGradient,
    LinearGradient? secondaryGradient,
    LinearGradient? successGradient,
    Color? badgeColor,
    LinearGradient? fabGradient,
    LinearGradient? appBarTitleGradient,
    List<BoxShadow>? chatCardShadow,
    Color? surfaceVariant,
    Color? shadowLight,
    Color? shadowMedium,
    Color? secondary,
    Color? info,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return ChinguTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      glassGradient: glassGradient ?? this.glassGradient,
      transparentGradient: transparentGradient ?? this.transparentGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      successGradient: successGradient ?? this.successGradient,
      badgeColor: badgeColor ?? this.badgeColor,
      fabGradient: fabGradient ?? this.fabGradient,
      appBarTitleGradient: appBarTitleGradient ?? this.appBarTitleGradient,
      chatCardShadow: chatCardShadow ?? this.chatCardShadow,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      shadowLight: shadowLight ?? this.shadowLight,
      shadowMedium: shadowMedium ?? this.shadowMedium,
      secondary: secondary ?? this.secondary,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  ThemeExtension<ChinguTheme> lerp(ThemeExtension<ChinguTheme>? other, double t) {
    if (other is! ChinguTheme) return this;
    
    return ChinguTheme(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      accentGradient: LinearGradient.lerp(accentGradient, other.accentGradient, t)!,
      glassGradient: LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
      transparentGradient: LinearGradient.lerp(transparentGradient, other.transparentGradient, t)!,
      secondaryGradient: LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
      successGradient: LinearGradient.lerp(successGradient, other.successGradient, t)!,
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t)!,
      fabGradient: LinearGradient.lerp(fabGradient, other.fabGradient, t)!,
      appBarTitleGradient: LinearGradient.lerp(appBarTitleGradient, other.appBarTitleGradient, t)!,
      chatCardShadow: BoxShadow.lerpList(chatCardShadow, other.chatCardShadow, t) ?? chatCardShadow,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      shadowMedium: Color.lerp(shadowMedium, other.shadowMedium, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }

  // Factory for Minimal Theme (Morandi Warm)
  static final minimal = ChinguTheme(
    primaryGradient: AppColorsMinimal.primaryGradient,
    accentGradient: AppColorsMinimal.accentGradient,
    glassGradient: AppColorsMinimal.glassGradient,
    transparentGradient: AppColorsMinimal.transparentGradient,
    secondaryGradient: AppColorsMinimal.secondaryGradient,
    successGradient: AppColorsMinimal.successGradient,
    badgeColor: AppColorsMinimal.secondary, // 磚橘色
    fabGradient: AppColorsMinimal.accentGradient,
    appBarTitleGradient: AppColorsMinimal.primaryGradient,
    chatCardShadow: [
      BoxShadow(
        color: AppColorsMinimal.shadowMedium,
        blurRadius: 10,
        offset: const Offset(0, 4),
      )
    ],
    surfaceVariant: AppColorsMinimal.surfaceVariant,
    shadowLight: AppColorsMinimal.shadowLight,
    shadowMedium: AppColorsMinimal.shadowMedium,
    secondary: AppColorsMinimal.secondary,
    info: AppColorsMinimal.info,
    success: AppColorsMinimal.success,
    warning: AppColorsMinimal.warning,
    error: AppColorsMinimal.error,
  );

  // Factory for Original Orange Theme (Fallback)
  static final orange = ChinguTheme(
    primaryGradient: const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)]),
    accentGradient: const LinearGradient(colors: [Color(0xFF80CBC4), Color(0xFFB2DFDB)]),
    glassGradient: const LinearGradient(colors: [Color(0x30FFFFFF), Color(0x10FFFFFF)]),
    transparentGradient: const LinearGradient(colors: [Color(0x2064B5F6), Color(0x1064B5F6)]),
    secondaryGradient: const LinearGradient(colors: [Color(0xFF80CBC4), Color(0xFFB2DFDB)]),
    successGradient: const LinearGradient(colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)]),
    badgeColor: const Color(0xFFEF5350),
    fabGradient: const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)]),
    appBarTitleGradient: const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)]),
    chatCardShadow: [
      const BoxShadow(
        color: Color(0x1478909C),
        blurRadius: 8,
        offset: Offset(0, 2),
      )
    ],
    surfaceVariant: const Color(0xFFECF0F6),
    shadowLight: const Color(0x0A78909C),
    shadowMedium: const Color(0x1478909C),
    secondary: const Color(0xFF80CBC4),
    info: const Color(0xFF42A5F5),
    success: const Color(0xFF66BB6A),
    warning: const Color(0xFFFFB74D),
    error: const Color(0xFFEF5350),
  );
}

class AppTheme {
  static ThemeData themeFor(AppThemePreset preset, {Brightness brightness = Brightness.light}) {
    final seed = switch (preset) {
      AppThemePreset.orange => const Color(0xFFFF6B35),
      AppThemePreset.minimal => AppColorsMinimal.primary,
      AppThemePreset.blue => const Color(0xFF2962FF),
      AppThemePreset.green => const Color(0xFF2E7D32),
      AppThemePreset.purple => const Color(0xFF6A1B9A),
      AppThemePreset.pink => const Color(0xFFD81B60),
    };

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      // Minimal theme overrides to use AppColorsMinimal tokens
      primary: preset == AppThemePreset.minimal ? AppColorsMinimal.primary : null,
      secondary: preset == AppThemePreset.minimal ? AppColorsMinimal.secondary : null,
      // background is deprecated, use surface
      surface: preset == AppThemePreset.minimal ? AppColorsMinimal.background : null,
      error: preset == AppThemePreset.minimal ? AppColorsMinimal.error : null,
    );

    final chinguTheme = preset == AppThemePreset.minimal ? ChinguTheme.minimal : ChinguTheme.orange;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset == AppThemePreset.minimal 
          ? AppColorsMinimal.background 
          : colorScheme.surface,
      fontFamily: 'NotoSansTC',
      extensions: [chinguTheme],
      
      appBarTheme: AppBarTheme(
        backgroundColor: preset == AppThemePreset.minimal ? AppColorsMinimal.background : colorScheme.primary,
        foregroundColor: preset == AppThemePreset.minimal ? AppColorsMinimal.textPrimary : colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset == AppThemePreset.minimal ? AppColorsMinimal.surface : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset == AppThemePreset.minimal ? AppColorsMinimal.surfaceVariant : colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset == AppThemePreset.minimal ? AppColorsMinimal.surfaceVariant : colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: preset == AppThemePreset.minimal ? AppColorsMinimal.surface : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: preset == AppThemePreset.minimal ? const BorderSide(color: AppColorsMinimal.surfaceVariant) : BorderSide.none,
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}

class ThemeController extends ChangeNotifier {
  AppThemePreset _preset = AppThemePreset.minimal;
  bool _darkMode = false;

  AppThemePreset get preset => _preset;
  bool get darkMode => _darkMode;

  ThemeData get theme => AppTheme.themeFor(_preset, brightness: _darkMode ? Brightness.dark : Brightness.light);

  void setPreset(AppThemePreset preset) {
    if (_preset == preset) return;
    _preset = preset;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
  }
}
