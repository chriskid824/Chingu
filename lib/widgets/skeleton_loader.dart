import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final ShapeBorder shape;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shape = const RoundedRectangleBorder();

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shape = const CircleBorder(),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            color: baseColor,
            shape: widget.shape,
          ),
          child: FractionallySizedBox(
            widthFactor: 1.5,
            child: Transform.translate(
              offset: Offset(
                -widget.width + (widget.width * 2 * _controller.value),
                0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      highlightColor,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: const Alignment(-1.0, -0.3),
                    end: const Alignment(1.0, 0.3),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonEventCard extends StatelessWidget {
  const SkeletonEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerWidget.rectangular(height: 48, width: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerWidget.rectangular(height: 16, width: 120),
                    SizedBox(height: 8),
                    ShimmerWidget.rectangular(height: 12, width: 60),
                  ],
                ),
              ),
              const ShimmerWidget.rectangular(height: 24, width: 60),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerWidget.rectangular(height: 80),
        ],
      ),
    );
  }
}
