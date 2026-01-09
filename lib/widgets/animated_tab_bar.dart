import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class AnimatedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final TextStyle? labelStyle;
  final TextStyle? selectedLabelStyle;
  final EdgeInsetsGeometry padding;
  final double height;
  final Duration animationDuration;

  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.backgroundColor,
    this.indicatorColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.padding = const EdgeInsets.all(4),
    this.height = 48,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final bgColor = backgroundColor ?? theme.cardColor;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height / 2 + 4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / tabs.length;

          return Stack(
            children: [
              // Sliding Indicator
              AnimatedAlign(
                alignment: Alignment(
                  tabs.length > 1
                      ? -1.0 + (selectedIndex * 2.0 / (tabs.length - 1))
                      : 0.0,
                  0.0,
                ),
                duration: animationDuration,
                curve: Curves.easeInOut,
                child: Container(
                  width: tabWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    gradient: indicatorColor == null ? chinguTheme?.primaryGradient : null,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab Labels
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: (isSelected
                                  ? (selectedLabelStyle ?? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white))
                                  : (labelStyle ?? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface.withOpacity(0.6)))) ??
                              const TextStyle(),
                          child: Text(
                            tabs[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
