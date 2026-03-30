import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_animations.dart';

/// 通用按鈕回彈 wrapper
///
/// 包裹任意 child widget，點擊時縮放至 0.95 再回彈。
/// 規格：ScaleTransition 縮至 0.95，150ms，easeInOut
class BounceButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const BounceButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.bounceButton,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.bounceScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.bounceCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
