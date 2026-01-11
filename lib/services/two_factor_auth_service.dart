import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 集合名稱
  static const String _collection = 'two_factor_codes';

  /// 發送驗證碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [method] 發送方式 ('email' 或 'sms')
  /// [uid] 用戶 ID (如果已知)
  Future<void> sendVerificationCode({
    required String target,
    required String method,
    String? uid,
  }) async {
    try {
      // 驗證輸入格式
      _validateTarget(target, method);

      // 檢查冷卻時間
      final canSend = await canResend(target);
      if (!canSend) {
        throw Exception('請稍後再試 (60秒冷卻時間)');
      }

      // 1. 生成 6 位數驗證碼
      final code = _generateCode();

      // 2. 設定過期時間 (10分鐘)
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // 3. 儲存到 Firestore
      await _firestore.collection(_collection).doc(target).set({
        // TODO: In production, do NOT store the plain text code in a client-readable document.
        // This should be handled by a Cloud Function that stores a hash or handles verification.
        // For this demo/MVP, we assume strict Firestore Security Rules prevent client read access.
        'code': code,
        'method': method,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid, // 可選，用於關聯
        'attempts': 0, // 重試次數
      });

      // 4. 發送代碼 (模擬)
      _mockSendCode(target, code, method);

    } catch (e) {
      debugPrint('發送驗證碼失敗: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 檢查是否可以重發驗證碼 (60秒冷卻)
  Future<bool> canResend(String target) async {
    try {
      final doc = await _firestore.collection(_collection).doc(target).get();
      if (!doc.exists) return true;

      final data = doc.data();
      if (data == null || !data.containsKey('createdAt')) return true;

      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final difference = DateTime.now().difference(createdAt);

      return difference.inSeconds >= 60;
    } catch (e) {
      // 如果發生錯誤 (如權限問題)，保守起見允許重發，或記錄錯誤
      debugPrint('檢查冷卻時間失敗: $e');
      return true;
    }
  }

  /// 驗證代碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [code] 用戶輸入的驗證碼
  /// 返回是否驗證成功
  Future<bool> verifyCode(String target, String code) async {
    try {
      // 模擬 Cloud Function 的行為
      // TODO: Migrate to Cloud Functions for secure verification.
      final docRef = _firestore.collection(_collection).doc(target);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('驗證碼不存在或已過期');
      }

      final data = doc.data() as Map<String, dynamic>;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final savedCode = data['code'] as String;
      final attempts = data['attempts'] as int? ?? 0;

      // 檢查是否過期
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('驗證碼已過期');
      }

      // 檢查嘗試次數 (防止暴力破解)
      if (attempts >= 5) {
        throw Exception('嘗試次數過多，請重新發送');
      }

      // 檢查代碼是否匹配
      if (savedCode == code) {
        // 驗證成功，刪除代碼
        await docRef.delete();
        return true;
      } else {
        // 驗證失敗，增加嘗試次數
        await docRef.update({
          'attempts': FieldValue.increment(1),
        });
        return false;
      }
    } catch (e) {
      debugPrint('驗證代碼失敗: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('驗證失敗: $e');
    }
  }

  /// 啟用 2FA
  ///
  /// [uid] 用戶 ID
  /// [method] 驗證方式 ('email' 或 'sms')
  /// [phoneNumber] 電話號碼 (如果 method 是 sms)
  Future<void> enableTwoFactor(String uid, String method, {String? phoneNumber}) async {
    try {
      if (method == 'sms') {
        if (phoneNumber == null || phoneNumber.isEmpty) {
          throw Exception('啟用 SMS 驗證需要電話號碼');
        }
        _validateTarget(phoneNumber, 'sms');
      } else if (method == 'email') {
         // 通常 email 已經在 auth 中，但如果需要額外確認也可以
      }

      final updates = {
        'isTwoFactorEnabled': true,
        'twoFactorMethod': method,
      };

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      await _firestoreService.updateUser(uid, updates);
    } catch (e) {
      debugPrint('啟用 2FA 失敗: $e');
      throw Exception('啟用 2FA 失敗: $e');
    }
  }

  /// 停用 2FA
  ///
  /// [uid] 用戶 ID
  Future<void> disableTwoFactor(String uid) async {
    try {
      await _firestoreService.updateUser(uid, {
        'isTwoFactorEnabled': false,
      });
    } catch (e) {
      debugPrint('停用 2FA 失敗: $e');
      throw Exception('停用 2FA 失敗: $e');
    }
  }

  /// 驗證輸入格式
  void _validateTarget(String target, String method) {
    if (method == 'email') {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(target)) {
        throw Exception('無效的 Email 格式');
      }
    } else if (method == 'sms') {
      // 簡單的手機號碼驗證 (支援國際格式)
      final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
      if (!phoneRegex.hasMatch(target)) {
        throw Exception('無效的電話號碼格式');
      }
    } else {
      throw Exception('不支援的驗證方式: $method');
    }
  }

  /// 生成 6 位數隨機代碼
  String _generateCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// 模擬發送代碼
  void _mockSendCode(String target, String code, String method) {
    // 這裡實際上會調用 SMS 網關 (如 Twilio) 或 Email 服務 (如 SendGrid)
    debugPrint('==========================================');
    debugPrint('MOCK SENDING 2FA CODE ($method)');
    debugPrint('To: $target');
    debugPrint('Code: $code');
    debugPrint('==========================================');
  }
}
