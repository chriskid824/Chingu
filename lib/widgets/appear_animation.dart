import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_animations.dart';

/// 卡片出現動畫 wrapper
///
/// 底部上移 + 淡入，easeOutCubic 400ms
/// 規格：SlideTransition 底部上移 + FadeTransition, 400ms
class AppearAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AppearAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.cardAppear,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.cardAppearCurve,
    );

    _slideAnimation = Tween<Offset>(
      begin: AppAnimations.cardSlideBegin,
      end: AppAnimations.cardSlideEnd,
    ).animate(curved);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
