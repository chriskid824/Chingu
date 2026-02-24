import 'package:flutter/services.dart';

/// 觸覺回饋工具類
class HapticUtils {
  /// 輕觸覺回饋
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// 中等觸覺回饋
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// 重觸覺回饋
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// 選擇觸覺回饋
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// 振動回饋
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}
