import 'package:flutter/material.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

/// 靜音時段服務 - 處理勿擾模式邏輯
class SilentHoursService {
  final FirestoreService _firestoreService;

  SilentHoursService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// 儲存靜音時段設定
  ///
  /// [uid] 用戶 ID
  /// [enabled] 是否啟用
  /// [start] 開始時間
  /// [end] 結束時間
  Future<void> saveSilentHoursSettings(
    String uid,
    bool enabled,
    TimeOfDay start,
    TimeOfDay end,
  ) async {
    try {
      final startStr = _formatTimeOfDay(start);
      final endStr = _formatTimeOfDay(end);

      await _firestoreService.updateUser(uid, {
        'isSilentHoursEnabled': enabled,
        'silentHoursStart': startStr,
        'silentHoursEnd': endStr,
      });
    } catch (e) {
      throw Exception('儲存靜音時段設定失敗: $e');
    }
  }

  /// 檢查當前是否為靜音時段
  ///
  /// [start] 開始時間
  /// [end] 結束時間
  /// [currentTime] 當前時間
  bool isSilentTime(TimeOfDay start, TimeOfDay end, DateTime currentTime) {
    final nowTime = TimeOfDay.fromDateTime(currentTime);

    // Convert to minutes for easier comparison
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;

    if (startMinutes <= endMinutes) {
      // e.g., 09:00 to 17:00 (Standard working hours)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // e.g., 22:00 to 07:00 (Overnight)
      // Silent if time is AFTER start OR BEFORE end
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// 檢查是否應該發送通知
  ///
  /// [user] 目標用戶
  /// [currentTime] 當前時間 (預設為 now)
  bool shouldNotify(UserModel user, {DateTime? currentTime}) {
    if (!user.isSilentHoursEnabled) {
      return true;
    }

    final now = currentTime ?? DateTime.now();
    final start = _parseTimeString(user.silentHoursStart);
    final end = _parseTimeString(user.silentHoursEnd);

    if (start == null || end == null) {
      // Fallback: if parsing fails, assume we should notify (or handle error)
      return true;
    }

    // Return true only if it is NOT silent time
    return !isSilentTime(start, end, now);
  }

  // --- Helper Methods ---

  /// 將 TimeOfDay 格式化為 HH:mm 字串
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 將 HH:mm 字串解析為 TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}
