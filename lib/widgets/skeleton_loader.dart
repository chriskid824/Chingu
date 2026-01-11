import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  });

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
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
    final isLight = theme.brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey[300]! : Colors.grey[800]!;
    final highlightColor = isLight ? Colors.grey[100]! : Colors.grey[700]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            color: baseColor,
            shape: widget.shapeBorder,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonMatchCard extends StatelessWidget {
  const SkeletonMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const Expanded(
            child: ShimmerWidget.rectangular(
              height: double.infinity,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
          // Info placeholder
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget.rectangular(height: 24, width: 150),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(height: 16, width: 200),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    ShimmerWidget.rectangular(
                        height: 32, width: 80, shapeBorder: StadiumBorder()),
                    SizedBox(width: 8),
                    ShimmerWidget.rectangular(
                        height: 32, width: 80, shapeBorder: StadiumBorder()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonChatTile extends StatelessWidget {
  const SkeletonChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: chinguTheme?.surfaceVariant ?? theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const ShimmerWidget.circular(width: 56, height: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerWidget.rectangular(height: 16, width: 100),
                    Spacer(),
                    ShimmerWidget.rectangular(height: 12, width: 40),
                  ],
                ),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(height: 14, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonEventCard extends StatelessWidget {
  const SkeletonEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerWidget.rectangular(height: 20, width: 120),
              ShimmerWidget.rectangular(height: 20, width: 60),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              ShimmerWidget.circular(width: 32, height: 32),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget.rectangular(height: 14, width: 80),
                  SizedBox(height: 4),
                  ShimmerWidget.rectangular(height: 14, width: 100),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerWidget.rectangular(height: 14, width: double.infinity),
        ],
      ),
    );
  }
}

class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: const [
                ShimmerWidget.circular(width: 100, height: 100),
                SizedBox(height: 16),
                ShimmerWidget.rectangular(height: 24, width: 150),
                SizedBox(height: 8),
                ShimmerWidget.rectangular(height: 16, width: 100),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                ShimmerWidget.rectangular(height: 40, width: 60),
                ShimmerWidget.rectangular(height: 40, width: 60),
                ShimmerWidget.rectangular(height: 40, width: 60),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Bio
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerWidget.rectangular(height: 20, width: 80),
                SizedBox(height: 16),
                ShimmerWidget.rectangular(height: 14, width: double.infinity),
                SizedBox(height: 8),
                ShimmerWidget.rectangular(height: 14, width: double.infinity),
                SizedBox(height: 8),
                ShimmerWidget.rectangular(height: 14, width: 200),
                SizedBox(height: 32),
                ShimmerWidget.rectangular(height: 20, width: 80),
                SizedBox(height: 16),
                Row(
                  children: [
                    ShimmerWidget.rectangular(
                        height: 32, width: 80, shapeBorder: StadiumBorder()),
                    SizedBox(width: 8),
                    ShimmerWidget.rectangular(
                        height: 32, width: 80, shapeBorder: StadiumBorder()),
                    SizedBox(width: 8),
                    ShimmerWidget.rectangular(
                        height: 32, width: 80, shapeBorder: StadiumBorder()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
