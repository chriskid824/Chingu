import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
      // 1. 生成 6 位數驗證碼
      final code = _generateCode();

      // 2. 設定過期時間 (10分鐘)
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // 3. 儲存到 Firestore
      // 如果有 uid，我們也可以用 uid 作為 key，但驗證時通常是用 target (如 email) 查找
      // 這裡我們用 target 作為文檔 ID，確保一個 target 同一時間只有一個有效 code
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
      throw Exception('發送驗證碼失敗: $e');
    }
  }

  /// 驗證代碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [code] 用戶輸入的驗證碼
  /// 返回是否驗證成功
  Future<bool> verifyCode(String target, String code) async {
    try {
      // Secure verification via Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('verifyTwoFactorCode')
          .call({
        'target': target,
        'code': code,
      });

      final data = result.data as Map<dynamic, dynamic>;
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function 驗證失敗: ${e.code} - ${e.message}');
      throw Exception(e.message); // 使用 Cloud Function 返回的具體錯誤訊息
    } catch (e) {
      debugPrint('驗證代碼失敗: $e');
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
      if (method == 'sms' && (phoneNumber == null || phoneNumber.isEmpty)) {
        throw Exception('啟用 SMS 驗證需要電話號碼');
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

  /// 生成 6 位數隨機代碼
  String _generateCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// 模擬發送代碼
  void _mockSendCode(String target, String code, String method) {
    // 這裡實際上會調用 SMS 網關 (如 Twilio) 或 Email 服務 (如 SendGrid)
    // 但在演示環境中，我們只打印到控制台
    debugPrint('==========================================');
    debugPrint('MOCK SENDING 2FA CODE');
    debugPrint('To: $target');
    debugPrint('Method: $method');
    debugPrint('Code: $code');
    debugPrint('==========================================');
  }
}
