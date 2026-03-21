import 'package:flutter/material.dart';
import 'app_colors_minimal.dart';

enum AppThemePreset {
  orange,    // 既有主題（暖橘）
  minimal,   // 極簡風格（靛藍紫）
  blue,      // 冷藍
  green,     // 清新綠
  purple,    // 高級紫
  pink,      // 活力粉
}

/// Custom Theme Extension for Chingu App
/// Allows accessing custom colors and gradients via Theme.of(context).extension<ChinguTheme>()
class ChinguTheme extends ThemeExtension<ChinguTheme> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient transparentGradient;
  final LinearGradient successGradient;
  final LinearGradient glassGradient;
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
    required this.secondaryGradient,
    required this.transparentGradient,
    required this.successGradient,
    required this.glassGradient,
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
    LinearGradient? secondaryGradient,
    LinearGradient? transparentGradient,
    LinearGradient? successGradient,
    LinearGradient? glassGradient,
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
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      transparentGradient: transparentGradient ?? this.transparentGradient,
      successGradient: successGradient ?? this.successGradient,
      glassGradient: glassGradient ?? this.glassGradient,
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
    if (other is! ChinguTheme) {
      return this;
    }
    return ChinguTheme(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      secondaryGradient: LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
      transparentGradient: LinearGradient.lerp(transparentGradient, other.transparentGradient, t)!,
      successGradient: LinearGradient.lerp(successGradient, other.successGradient, t)!,
      glassGradient: LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
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

  // Factory for Minimal Theme (now warm apricot/coral)
  static const minimal = ChinguTheme(
    primaryGradient: AppColorsMinimal.primaryGradient,
    secondaryGradient: AppColorsMinimal.secondaryGradient,
    transparentGradient: AppColorsMinimal.transparentGradient,
    successGradient: AppColorsMinimal.successGradient,
    glassGradient: AppColorsMinimal.glassGradient,
    surfaceVariant: AppColorsMinimal.surfaceVariant,
    shadowLight: AppColorsMinimal.shadowLight,
    shadowMedium: AppColorsMinimal.shadowMedium,
    secondary: AppColorsMinimal.secondary,
    info: AppColorsMinimal.info,
    success: AppColorsMinimal.success,
    warning: AppColorsMinimal.warning,
    error: AppColorsMinimal.error,
  );

  // Factory for Orange Theme (warm blue variant)
  static const orange = ChinguTheme(
    primaryGradient: LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)]),
    secondaryGradient: LinearGradient(colors: [Color(0xFF80CBC4), Color(0xFFB2DFDB)]),
    transparentGradient: LinearGradient(colors: [Color(0x2064B5F6), Color(0x1064B5F6)]),
    successGradient: LinearGradient(colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)]),
    glassGradient: LinearGradient(colors: [Color(0x30FFFFFF), Color(0x10FFFFFF)]),
    surfaceVariant: Color(0xFFECF0F6),
    shadowLight: Color(0x0A78909C),
    shadowMedium: Color(0x1478909C),
    secondary: Color(0xFF80CBC4),
    info: Color(0xFF42A5F5),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFEF5350),
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
      // Override specific colors for Minimal theme
      primary: preset == AppThemePreset.minimal ? AppColorsMinimal.primary : null,
      secondary: preset == AppThemePreset.minimal ? AppColorsMinimal.secondary : null,
      surface: preset == AppThemePreset.minimal ? AppColorsMinimal.surface : null,
      background: preset == AppThemePreset.minimal ? AppColorsMinimal.background : null,
      error: preset == AppThemePreset.minimal ? AppColorsMinimal.error : null,
    );

    final chinguTheme = preset == AppThemePreset.minimal ? ChinguTheme.minimal : ChinguTheme.orange;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset == AppThemePreset.minimal 
          ? AppColorsMinimal.background 
          : (brightness == Brightness.light ? colorScheme.background : colorScheme.surface),
      fontFamily: 'NotoSansTC',
      extensions: [chinguTheme], // Register the extension
      
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset == AppThemePreset.minimal ? AppColorsMinimal.surface : colorScheme.surfaceVariant.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          borderSide: BorderSide(color: preset == AppThemePreset.minimal ? AppColorsMinimal.surfaceVariant : colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          borderSide: BorderSide(color: preset == AppThemePreset.minimal ? AppColorsMinimal.surfaceVariant : colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        color: preset == AppThemePreset.minimal ? AppColorsMinimal.surface : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          side: preset == AppThemePreset.minimal ? const BorderSide(color: AppColorsMinimal.surfaceVariant) : BorderSide.none,
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}

class ThemeController extends ChangeNotifier {
  AppThemePreset _preset = AppThemePreset.minimal; // Default to Minimal for this demo
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



