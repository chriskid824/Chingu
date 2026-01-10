import 'package:flutter/material.dart';

/// A widget that animates a number from 0 to [value].
///
/// Useful for displaying statistics like matches, likes, rating, etc.
class AnimatedCounter extends StatelessWidget {
  /// The target value to animate to.
  final num value;

  /// The duration of the animation. Defaults to 1.5 seconds.
  final Duration duration;

  /// The text style to use.
  final TextStyle? style;

  /// Text to display before the number.
  final String prefix;

  /// Text to display after the number.
  final String suffix;

  /// Number of decimal places to show. Defaults to 0 (integer).
  final int decimalPlaces;

  /// The animation curve. Defaults to [Curves.fastOutSlowIn].
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.curve = Curves.fastOutSlowIn,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<num>(
      tween: Tween<num>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(
          '$prefix${value.toStringAsFixed(decimalPlaces)}$suffix',
          style: style,
        );
      },
    );
  }
}
