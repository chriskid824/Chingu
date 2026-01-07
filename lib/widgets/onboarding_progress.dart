import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class OnboardingProgressWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressWidget({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            // currentStep is 1-based (1, 2, 3, 4)
            // index is 0-based (0, 1, 2, 3)
            // If currentStep is 1: index 0 (0 < 1) should be active.
            // If currentStep is 4: indices 0,1,2,3 (all < 4) should be active.
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
