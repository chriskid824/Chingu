import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;

  TwoFactorAuthService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService(),
        _auth = auth ?? FirebaseAuth.instance;

  // 集合名稱
  static const String _collection = 'two_factor_codes';

  /// 發送驗證碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [method] 發送方式 ('email' 或 'sms')
  /// [uid] 用戶 ID (如果已知)
  ///
  /// 對於 SMS，返回 verificationId
  Future<String?> sendVerificationCode({
    required String target,
    required String method,
    String? uid,
  }) async {
    try {
      if (method == 'sms') {
        // 使用 Firebase Auth 驗證電話號碼
        final Completer<String> completer = Completer<String>();

        await _auth.verifyPhoneNumber(
          phoneNumber: target,
          verificationCompleted: (PhoneAuthCredential credential) {
            // Android 上可能會自動驗證
            // 這裡我們暫時只記錄日誌，因為我們主要需要 verificationId
            debugPrint('SMS 自動驗證完成: ${credential.smsCode}');
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!completer.isCompleted) completer.completeError(e);
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!completer.isCompleted) completer.complete(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // 超時，但我們仍然可以使用 verificationId
             if (!completer.isCompleted) completer.complete(verificationId);
          },
        );

        return completer.future;
      } else {
        // Email 方式：生成並儲存驗證碼到 Firestore
        // 1. 生成 6 位數驗證碼
        final code = _generateCode();

        // 2. 設定過期時間 (10分鐘)
        final expiresAt = DateTime.now().add(const Duration(minutes: 10));

        // 3. 儲存到 Firestore
        await _firestore.collection(_collection).doc(target).set({
          'code': code,
          'method': method,
          'expiresAt': Timestamp.fromDate(expiresAt),
          'createdAt': FieldValue.serverTimestamp(),
          'uid': uid,
          'attempts': 0,
        });

        // 4. 發送代碼 (模擬)
        _mockSendCode(target, code, method);

        return null;
      }
    } catch (e) {
      debugPrint('發送驗證碼失敗: $e');
      throw Exception('發送驗證碼失敗: $e');
    }
  }

  /// 驗證代碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [code] 用戶輸入的驗證碼
  /// [verificationId] SMS 驗證 ID (僅 SMS 需要)
  ///
  /// 返回是否驗證成功
  Future<bool> verifyCode(String target, String code, {String? verificationId}) async {
    try {
      if (verificationId != null) {
        // SMS 驗證
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code,
        );

        // 嘗試使用憑證登入/重新驗證
        // 注意：這可能會改變當前的登入狀態，這取決於具體業務邏輯
        // 這裡我們假設如果是 2FA，用戶可能已經登入（如啟用時）或正在登入流程中
        // 簡單驗證：如果能創建憑證並嘗試登入（即使最後不完成登入流程），通常表示驗證碼正確

        await _auth.signInWithCredential(credential);
        return true;
      } else {
        // Email/Mock 驗證
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
      }
    } catch (e) {
      debugPrint('驗證代碼失敗: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
           return false; // 明確返回 false
        }
      }
      // 如果是我們拋出的異常，直接重拋
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      // 對於其他錯誤，我們選擇重拋原始異常以便上層處理，
      // 或者拋出一個包裝後的異常
      if (e is FirebaseAuthException) {
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
