import 'dart:convert';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';

/// 資料匯出服務
class DataExportService {
  final FirestoreService _firestoreService = FirestoreService();

  /// 匯出用戶資料為 JSON 字串
  ///
  /// [uid] 用戶 ID
  Future<String> exportUserData(String uid) async {
    try {
      // 獲取用戶基本資料
      final UserModel? user = await _firestoreService.getUser(uid);

      if (user == null) {
        throw Exception('找不到用戶資料');
      }

      // 構建匯出資料結構
      // 這裡可以根據需要擴展，例如加入聊天記錄、活動歷史等
      final Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_profile': user.toMap(),
        'metadata': {
          'app_version': '1.0.0', // 應該從 package_info 獲取，這裡暫時寫死
          'platform': 'chingu_app',
        }
      };

      // 轉換為格式化的 JSON 字串
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(exportData);
    } catch (e) {
      throw Exception('匯出資料失敗: $e');
    }
  }
}
