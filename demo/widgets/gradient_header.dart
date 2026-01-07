import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final LinearGradient? gradient;

  const GradientHeader({
    super.key,
    required this.child,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: gradient ?? chinguTheme?.primaryGradient,
      ),
      child: child,
    );
  }
}
