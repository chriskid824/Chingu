import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const OnboardingProgressBar({
    super.key,
    this.totalSteps = 4,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            // Determine if this step block should be highlighted.
            // Blocks up to (currentStep - 1) are completed/active.
            // Example: currentStep = 1 (index 0). Index 0 < 1 is true.
            // Example: currentStep = 4 (index 0, 1, 2, 3). All < 4 are true.
            final isActive = index < currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: isActive ? chinguTheme?.primaryGradient : null,
                  color: isActive ? null : theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        Text(
          '步驟 $currentStep/$totalSteps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
