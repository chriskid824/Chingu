import 'dart:math';
import 'package:flutter/material.dart';

class SwipeableCardController {
  _SwipeableCardState? _state;

  void _bind(_SwipeableCardState state) {
    _state = state;
  }

  void _unbind() {
    _state = null;
  }

  Future<void> swipeLeft() async {
    await _state?.triggerSwipe(false);
  }

  Future<void> swipeRight() async {
    await _state?.triggerSwipe(true);
  }
}

class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final SwipeableCardController? controller;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.controller,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Offset _position = Offset.zero;
  double _angle = 0;
  bool _isDragging = false;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(() {
      setState(() {});
    });
    widget.controller?._bind(this);
  }

  @override
  void dispose() {
    widget.controller?._unbind();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      // Calculate angle: rotate more as we move further from center
      // Max rotation ~15 degrees (0.26 rad) at screen edge
      final double progress = _position.dx / _screenSize.width;
      _angle = progress * 0.5; // Adjust rotation sensitivity
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final double threshold = 100.0;
    // Check velocity to allow flick
    final double velocityX = details.velocity.pixelsPerSecond.dx;

    if (_position.dx > threshold || velocityX > 1000) {
      triggerSwipe(true);
    } else if (_position.dx < -threshold || velocityX < -1000) {
      triggerSwipe(false);
    } else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    final startPosition = _position;
    final startAngle = _angle;

    _animationController.duration = const Duration(milliseconds: 300);

    Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    void listener() {
      setState(() {
        _position = Offset.lerp(startPosition, Offset.zero, animation.value)!;
        _angle = Tween<double>(begin: startAngle, end: 0).evaluate(animation);
      });
    }

    animation.addListener(listener);
    _animationController.forward(from: 0).then((_) {
      animation.removeListener(listener);
    });
  }

  Future<void> triggerSwipe(bool isRight) async {
    final double endX = isRight ? _screenSize.width * 1.5 : -_screenSize.width * 1.5;
    // Slight arc effect: move Y slightly down or up depending on previous drag or random
    // But consistent linear is fine for "flying off"

    final startPosition = _position;
    final endPosition = Offset(endX, _position.dy + 50); // Add slight drop
    final startAngle = _angle;
    final endAngle = isRight ? 0.5 : -0.5; // Rotate towards the direction

    _animationController.duration = const Duration(milliseconds: 300);

    Animation<double> animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    void listener() {
      setState(() {
        _position = Offset.lerp(startPosition, endPosition, animation.value)!;
        _angle = Tween<double>(begin: startAngle, end: endAngle).evaluate(animation);
      });
    }

    animation.addListener(listener);
    await _animationController.forward(from: 0);
    animation.removeListener(listener);

    if (isRight) {
      widget.onSwipeRight?.call();
    } else {
      widget.onSwipeLeft?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _position,
        child: Transform.rotate(
          angle: _angle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              // Overlays
              if (_position.dx != 0) _buildOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final double progress = (_position.dx / 150).abs().clamp(0.0, 1.0);
    final bool isRight = _position.dx > 0;

    // Only show if dragged enough to be visible
    if (progress < 0.1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: (isRight ? Colors.green : Colors.red).withOpacity(0.2 * progress),
      ),
      child: Center(
        child: Transform.rotate(
          angle: isRight ? -0.2 : 0.2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: (isRight ? Colors.green : Colors.red).withOpacity(progress),
                width: 4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isRight ? 'LIKE' : 'NOPE',
              style: TextStyle(
                color: (isRight ? Colors.green : Colors.red).withOpacity(progress),
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
