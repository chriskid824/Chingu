import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

/// 倒數圓環 Widget — Apple Watch 環形進度條風格
/// 
/// 顯示距離晚餐活動的倒數時間，外圈為漸層進度環
class CountdownRing extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    
    // 計算進度（假設報名後 7 天為一個週期）
    final totalDuration = const Duration(days: 7);
    final elapsed = totalDuration - difference;
    final progress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);

    // 計算倒數顯示
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    final bool isToday = days == 0;
    final bool isPast = difference.isNegative;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景環
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              strokeWidth: strokeWidth,
              color: AppColorsMinimal.surfaceVariant,
            ),
          ),
          // 進度環
          CustomPaint(
            size: Size(size, size),
            painter: _GradientRingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              gradient: AppColorsMinimal.primaryGradient,
            ),
          ),
          // 中心文字
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPast) ...[
                const Icon(
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
              ] else if (isToday) ...[
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
              ] else ...[
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
            ],
          ),
        ],
      ),
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
