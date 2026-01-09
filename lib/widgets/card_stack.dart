import 'package:flutter/material.dart';

class CardStack<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Function(T item, DismissDirection direction) onSwipe;
  final int stackDepth;
  final Key Function(T item) keyBuilder;
  final double scaleFactor;
  final double yOffset;
  final Widget? swipeBackground;
  final Widget? swipeSecondaryBackground;

  const CardStack({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onSwipe,
    required this.keyBuilder,
    this.stackDepth = 3,
    this.scaleFactor = 0.05,
    this.yOffset = 15.0,
    this.swipeBackground,
    this.swipeSecondaryBackground,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Ensure we don't try to take more than available
    final count = items.length < stackDepth ? items.length : stackDepth;
    final visibleItems = items.take(count).toList();

    return Stack(
      alignment: Alignment.center,
      children: visibleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // 3D Effect Calculations
        // Index 0 is the top card (active)
        // Higher indices are further back
        final double scale = 1.0 - (index * scaleFactor);
        final double dy = index * yOffset;

        Widget card = itemBuilder(context, item, index);

        if (index == 0) {
          return Dismissible(
            key: keyBuilder(item),
            onDismissed: (direction) => onSwipe(item, direction),
            direction: DismissDirection.horizontal,
            background: swipeBackground,
            secondaryBackground: swipeSecondaryBackground,
            child: card,
          );
        } else {
          // Background cards
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              // Add a subtle fade for depth
              child: Opacity(
                opacity: 1.0 - (index * 0.1).clamp(0.0, 1.0),
                child: card,
              ),
            ),
          );
        }
      }).toList().reversed.toList(), // Reverse so index 0 is at the top of the stack
    );
  }
}
