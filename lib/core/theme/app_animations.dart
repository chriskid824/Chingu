import 'package:flutter/material.dart';

/// Chingu 統一動畫常量
///
/// 所有動畫曲線、時長、參數集中管理，確保全 App 動畫一致。
/// 規格來源：docs/roles/uiux_director.md
class AppAnimations {
  AppAnimations._();

  // ==================== 時長 ====================

  /// 按鈕回彈 150ms
  static const Duration bounceButton = Duration(milliseconds: 150);

  /// 頁面轉場 350ms
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// 卡片出現 400ms
  static const Duration cardAppear = Duration(milliseconds: 400);

  /// 狀態切換 (AnimatedSwitcher) 400ms
  static const Duration stateSwitch = Duration(milliseconds: 400);

  /// 解鎖翻牌 600ms
  static const Duration cardFlip = Duration(milliseconds: 600);

  // ==================== 曲線 ====================

  /// 頁面轉場曲線
  static const Curve pageTransitionCurve = Curves.easeOutCubic;

  /// 卡片出現曲線
  static const Curve cardAppearCurve = Curves.easeOutCubic;

  /// 按鈕回彈曲線
  static const Curve bounceCurve = Curves.easeInOut;

  // ==================== 按鈕回彈參數 ====================

  /// 按鈕按下縮放比例
  static const double bounceScale = 0.95;

  // ==================== 卡片出現參數 ====================

  /// 卡片從底部上移的初始偏移量
  static const Offset cardSlideBegin = Offset(0.0, 0.15);

  /// 卡片最終位置
  static const Offset cardSlideEnd = Offset.zero;
}
