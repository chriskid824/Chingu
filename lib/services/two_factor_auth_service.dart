import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
      final callable = _functions.httpsCallable('sendVerificationCode');
      await callable.call({
        'target': target,
        'method': method,
        'uid': uid,
      });
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
      final callable = _functions.httpsCallable('verifyVerificationCode');
      final result = await callable.call({
        'target': target,
        'code': code,
      });

      final data = result.data as Map<dynamic, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('驗證代碼失敗: $e');
      // Check if it's a Cloud Functions error with specific message
      if (e is FirebaseFunctionsException) {
         // If code is invalid or expired, the function might throw.
         // Specifically, for invalid code we throw 'invalid-argument'.
         if (e.code == 'invalid-argument') {
           return false;
         }
         // For 'not-found' or 'failed-precondition' (expired), we also consider it a failure.
         if (e.code == 'not-found' || e.code == 'failed-precondition') {
             return false;
         }

         throw Exception(e.message ?? '驗證失敗');
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
}
