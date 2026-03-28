import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

/// A reusable custom bottom sheet component with a drag handle and snap points.
///
/// This widget wraps [DraggableScrollableSheet] to provide a standardized appearance
/// and behavior for bottom sheets in the application. It includes a drag handle
/// at the top and supports snap points for various heights.
///
/// The [builder] provides a [ScrollController] that should be attached to the
/// scrollable content within the sheet to enable drag gestures.
///
/// Example usage:
/// ```dart
/// CustomBottomSheet(
///   initialChildSize: 0.5,
///   minChildSize: 0.25,
///   maxChildSize: 0.9,
///   snapSizes: [0.25, 0.5, 0.9],
///   builder: (context, scrollController) {
///     return ListView.builder(
///       controller: scrollController,
///       itemCount: 20,
///       itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///     );
///   },
/// )
/// ```
class CustomBottomSheet extends StatelessWidget {
  /// The builder that creates the scrollable content of the bottom sheet.
  ///
  /// The builder is called with a [ScrollController] that must be attached to
  /// the scrollable widget (e.g., [ListView], [SingleChildScrollView]) to allow
  /// the sheet to be dragged.
  final Widget Function(BuildContext, ScrollController) builder;

  /// The initial fractional height of the bottom sheet (0.0 to 1.0).
  final double initialChildSize;

  /// The minimum fractional height of the bottom sheet (0.0 to 1.0).
  final double minChildSize;

  /// The maximum fractional height of the bottom sheet (0.0 to 1.0).
  final double maxChildSize;

  /// A list of fractional heights where the bottom sheet should snap to.
  ///
  /// If provided, [snap] will be set to true.
  final List<double>? snapSizes;

  /// Whether the bottom sheet should snap to specific sizes.
  ///
  /// Defaults to true.
  final bool snap;

  /// An optional controller to programmatically control the bottom sheet's position.
  final DraggableScrollableController? controller;

  const CustomBottomSheet({
    super.key,
    required this.builder,
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 1.0,
    this.snapSizes,
    this.snap = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use card color for surface or fall back to scaffold background
    // In ChinguTheme, surface is often distinct from background.
    final backgroundColor = theme.cardColor;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      snapSizes: snapSizes,
      controller: controller,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: builder(context, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
}
