import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool isPlaying;
  final List<Color>? colors;

  const ConfettiWidget({
    super.key,
    this.isPlaying = true,
    this.colors,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _controller.addListener(_updateParticles);

    // Initialize particles
    // We want some to already be falling to simulate immediate celebration
    for (int i = 0; i < 50; i++) {
      _particles.add(_createParticle(startAtTop: false));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!widget.isPlaying) return;

    for (var particle in _particles) {
      particle.y += particle.speed;
      particle.rotation += particle.rotationSpeed;

      // If particle goes off screen bottom, reset to top
      if (particle.y > 1.0) {
        _resetParticle(particle);
      }
    }
    setState(() {});
  }

  _ConfettiParticle _createParticle({bool startAtTop = true}) {
    final colors = widget.colors ??
        [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.cyan,
          Colors.pink,
        ];

    return _ConfettiParticle(
      x: _random.nextDouble(),
      y: startAtTop ? -0.1 : _random.nextDouble() - 0.2, // Start slightly above or scattered
      size: _random.nextDouble() * 6 + 4, // 4 to 10
      color: colors[_random.nextInt(colors.length)],
      speed: _random.nextDouble() * 0.015 + 0.005, // Speed variation
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
    );
  }

  void _resetParticle(_ConfettiParticle particle) {
    particle.y = -0.1;
    particle.x = _random.nextDouble();
    particle.rotation = _random.nextDouble() * 2 * pi;
    // We keep size/color/speed constant for a particle or could randomize again
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double rotation;
  double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color;

      canvas.save();
      // Convert normalized coordinates (0..1) to pixel coordinates
      canvas.translate(particle.x * size.width, particle.y * size.height);
      canvas.rotate(particle.rotation);

      // Draw a small rectangle for the confetti piece
      // Width is particle.size, height is slightly smaller to look like a strip
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
