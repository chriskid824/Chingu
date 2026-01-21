import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TwoFactorAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 生成並發送驗證碼
  ///
  /// [uid] 用戶 ID
  /// [method] 驗證方式 ('email' 或 'sms')
  Future<void> sendVerificationCode(String uid, {String method = 'email'}) async {
    try {
      // 1. 生成 6 位數驗證碼
      final code = _generateCode();

      // 2. 設定過期時間 (5分鐘後)
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      // 3. 儲存到 Firestore (模擬後端儲存)
      // 注意：在生產環境中，這應該由後端 Cloud Function 處理，不應由客戶端直接寫入
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('two_factor')
          .doc('current')
          .set({
        'code': code,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'method': method,
        'createdAt': FieldValue.serverTimestamp(),
        'attempts': 0,
      });

      // 4. 模擬發送 (印出到 Console)
      debugPrint('==========================================');
      debugPrint('【2FA 模擬發送】');
      debugPrint('用戶: $uid');
      debugPrint('方式: $method');
      debugPrint('驗證碼: $code');
      debugPrint('==========================================');

    } catch (e) {
      debugPrint('發送驗證碼失敗: $e');
      throw Exception('發送驗證碼失敗，請稍後再試');
    }
  }

  /// 驗證代碼
  ///
  /// [uid] 用戶 ID
  /// [code] 用戶輸入的驗證碼
  ///
  /// 返回是否驗證成功
  Future<bool> verifyVerificationCode(String uid, String code) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('two_factor')
          .doc('current');

      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('驗證碼已失效，請重新發送');
      }

      final data = doc.data() as Map<String, dynamic>;
      final String correctCode = data['code'];
      final Timestamp expiresAt = data['expiresAt'];
      final int attempts = data['attempts'] ?? 0;

      // 檢查是否嘗試過多
      if (attempts >= 3) {
        throw Exception('嘗試次數過多，請重新發送驗證碼');
      }

      // 檢查是否過期
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        throw Exception('驗證碼已過期，請重新發送');
      }

      // 檢查代碼是否正確
      if (code == correctCode) {
        // 驗證成功，刪除驗證碼
        await docRef.delete();
        return true;
      } else {
        // 驗證失敗，增加嘗試次數
        await docRef.update({'attempts': FieldValue.increment(1)});
        return false;
      }
    } catch (e) {
      if (e is Exception) rethrow; // 重新拋出已知的業務異常
      throw Exception('驗證過程發生錯誤: $e');
    }
  }

  /// 生成 6 位隨機數字
  String _generateCode() {
    final rng = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += rng.nextInt(10).toString();
    }
    return code;
  }
}
