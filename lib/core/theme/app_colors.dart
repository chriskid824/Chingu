import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF06A77D);
  static const Color warning = Color(0xFFF4D35E);
  static const Color error = Color(0xFFEF476F);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFFF8C61)],
  );
  
  static Color primaryLight = primary.withOpacity(0.1);
  static Color shadowColor = Colors.black.withOpacity(0.1);
  static const Color divider = Color(0xFFE5E7EB);
}
