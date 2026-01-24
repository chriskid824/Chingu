import 'package:flutter/services.dart';

class HapticUtils {
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
}
