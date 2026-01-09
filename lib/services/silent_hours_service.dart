import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 勿擾模式服務
///
/// 負責管理和檢查勿擾模式的狀態和時間設定。
/// 使用 SharedPreferences 進行本地儲存。
class SilentHoursService {
  static final SilentHoursService _instance = SilentHoursService._internal();
  static const String _prefEnabled = 'silent_hours_enabled';
  static const String _prefStart = 'silent_hours_start';
  static const String _prefEnd = 'silent_hours_end';

  factory SilentHoursService() {
    return _instance;
  }

  SilentHoursService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// 初始化服務
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  /// 獲取勿擾模式是否啟用
  bool get isEnabled => _prefs.getBool(_prefEnabled) ?? false;

  /// 獲取開始時間
  TimeOfDay get startTime {
    final timeStr = _prefs.getString(_prefStart);
    if (timeStr == null) return const TimeOfDay(hour: 22, minute: 0);
    return _parseTime(timeStr);
  }

  /// 獲取結束時間
  TimeOfDay get endTime {
    final timeStr = _prefs.getString(_prefEnd);
    if (timeStr == null) return const TimeOfDay(hour: 7, minute: 0);
    return _parseTime(timeStr);
  }

  /// 設定勿擾模式狀態
  Future<void> setEnabled(bool enabled) async {
    await _checkInitialized();
    await _prefs.setBool(_prefEnabled, enabled);
  }

  /// 設定勿擾時間
  Future<void> setSilentHours(TimeOfDay start, TimeOfDay end) async {
    await _checkInitialized();
    await _prefs.setString(_prefStart, _formatTime(start));
    await _prefs.setString(_prefEnd, _formatTime(end));
  }

  /// 檢查當前是否處於勿擾時間
  ///
  /// 如果勿擾模式未啟用，總是返回 false。
  /// 如果啟用，則檢查當前時間是否在設定的時間範圍內。
  bool isSilentTime([DateTime? currentTime]) {
    if (!isEnabled) return false;

    final now = currentTime ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // 當天範圍 (e.g., 09:00 - 17:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // 跨天範圍 (e.g., 22:00 - 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  Future<void> _checkInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
