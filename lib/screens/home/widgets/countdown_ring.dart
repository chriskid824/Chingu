import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

/// 倒數圓環 Widget — Apple Watch 環形進度條風格
///
/// 顯示距離晚餐活動的倒數時間，外圈為漸層進度環。
/// 每 30 秒自動刷新倒數顯示。
class CountdownRing extends StatefulWidget {
  final DateTime targetDate;
  final double size;
  final double strokeWidth;

  const CountdownRing({
    super.key,
    required this.targetDate,
    this.size = 180,
    this.strokeWidth = 12,
  });

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _updateProgress();

    // 每 30 秒刷新
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _updateProgress();
    });
  }

  void _updateProgress() {
    final totalDuration = const Duration(days: 7);
    final difference = widget.targetDate.difference(DateTime.now());
    final elapsed = totalDuration - difference;
    final newProgress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);

    _progressAnimation = Tween<double>(
      begin: _currentProgress,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _currentProgress = newProgress;
    _animController.forward(from: 0);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difference = widget.targetDate.difference(DateTime.now());
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final bool isToday = days == 0 && !difference.isNegative;
    final bool isPast = difference.isNegative;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 背景環
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  strokeWidth: widget.strokeWidth,
                  color: AppColorsMinimal.surfaceVariant,
                ),
              ),
              // 漸層進度環（動畫）
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GradientRingPainter(
                  progress: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  gradient: AppColorsMinimal.primaryGradient,
                ),
              ),
              // 中心文字
              child!,
            ],
          );
        },
        child: _buildCenterText(isPast, isToday, days, hours, minutes),
      ),
    );
  }

  Widget _buildCenterText(
    bool isPast, bool isToday, int days, int hours, int minutes,
  ) {
    if (isPast) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.celebration_rounded,
            color: AppColorsMinimal.primary,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            '晚餐時間！',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
        ],
      );
    }

    if (isToday) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '今天',
            style: TextStyle(
              fontSize: 12,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$hours 小時',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.primary,
            ),
          ),
          Text(
            '$minutes 分鐘',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '還有',
          style: TextStyle(
            fontSize: 12,
            color: AppColorsMinimal.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$days 天',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.primary,
          ),
        ),
        Text(
          '$hours 小時 $minutes 分',
          style: TextStyle(
            fontSize: 13,
            color: AppColorsMinimal.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 單色環形畫家
class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 漸層環形畫家
class _GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final LinearGradient gradient;

  _GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: gradient.colors,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
