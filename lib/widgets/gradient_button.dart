import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    final isDisabled = onPressed == null || isLoading;

    final effectiveGradient = gradient ?? chinguTheme?.primaryGradient ?? 
        LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : effectiveGradient,
        color: isDisabled ? theme.disabledColor : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled ? [] : [
          BoxShadow(
            color: effectiveGradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? Colors.white.withOpacity(0.6) : Colors.white,
                ),
              ),
      ),
    );
  }
}
