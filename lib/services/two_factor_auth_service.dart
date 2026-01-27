import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  TwoFactorAuthService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  // 集合名稱
  static const String _collection = 'two_factor_codes';

  /// 發送驗證碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [method] 發送方式 ('email' 或 'sms')
  /// [uid] 用戶 ID (如果已知)
  ///
  /// 如果是 SMS，返回 verificationId (如果 Android 自動驗證成功，返回 'auto-verified')
  Future<String?> sendVerificationCode({
    required String target,
    required String method,
    String? uid,
  }) async {
    try {
      if (method == 'sms') {
        return await _sendSMSCode(target);
      } else {
        await _sendEmailCode(target, uid);
        return null;
      }
    } catch (e) {
      debugPrint('發送驗證碼失敗: $e');
      throw Exception('發送驗證碼失敗: $e');
    }
  }

  /// 處理憑證 (登入或連結)
  Future<void> _handleCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user != null) {
      // 如果用戶已登入，連結憑證
      await user.linkWithCredential(credential);
    } else {
      // 如果未登入，登入
      await _auth.signInWithCredential(credential);
    }
  }

  /// 發送 SMS 驗證碼 (使用 Firebase Auth)
  Future<String> _sendSMSCode(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('SMS 自動驗證完成');
        try {
          await _handleCredential(credential);
          if (!completer.isCompleted) {
            completer.complete('auto-verified');
          }
        } catch (e) {
          debugPrint('自動驗證處理失敗: $e');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('SMS 驗證失敗: ${e.message}');
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? '驗證失敗'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('SMS 驗證碼已發送');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('SMS 自動檢索超時');
        // 超時不代表失敗，只是不能自動填入了
      },
    );

    return completer.future;
  }

  /// 發送 Email 驗證碼 (模擬/Firestore)
  Future<void> _sendEmailCode(String email, String? uid) async {
    // 1. 生成 6 位數驗證碼
    final code = _generateCode();

    // 2. 設定過期時間 (10分鐘)
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    // 3. 儲存到 Firestore
    await _firestore.collection(_collection).doc(email).set({
      'code': code,
      'method': 'email',
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
      'uid': uid,
      'attempts': 0,
    });

    // 4. 發送代碼 (模擬)
    _mockSendCode(email, code, 'email');
  }

  /// 驗證代碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [code] 用戶輸入的驗證碼
  /// [verificationId] SMS 驗證所需的 ID
  /// 返回是否驗證成功
  Future<bool> verifyCode({
    required String target,
    required String code,
    String? verificationId,
  }) async {
    // 如果提供了 verificationId，嘗試 SMS 驗證
    if (verificationId != null) {
      if (verificationId == 'auto-verified') {
        return true;
      }
      return await _verifySMSCode(verificationId, code);
    } else {
      return await _verifyEmailCode(target, code);
    }
  }

  /// 驗證 SMS 代碼
  Future<bool> _verifySMSCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _handleCredential(credential);

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw Exception('驗證碼無效');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception('此電話號碼已被其他帳號使用');
      }
      debugPrint('SMS 驗證失敗: $e');
      throw Exception('驗證失敗: ${e.message}');
    } catch (e) {
      throw Exception('驗證過程發生錯誤: $e');
    }
  }

  /// 驗證 Email 代碼
  Future<bool> _verifyEmailCode(String email, String code) async {
    try {
      final docRef = _firestore.collection(_collection).doc(email);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('驗證碼不存在或已過期');
      }

      final data = doc.data() as Map<String, dynamic>;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final savedCode = data['code'] as String;
      final attempts = data['attempts'] as int? ?? 0;

      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('驗證碼已過期');
      }

      if (attempts >= 5) {
        throw Exception('嘗試次數過多，請重新發送');
      }

      if (savedCode == code) {
        await docRef.delete();
        return true;
      } else {
        await docRef.update({
          'attempts': FieldValue.increment(1),
        });
        return false;
      }
    } catch (e) {
      debugPrint('驗證 Email 代碼失敗: $e');
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
    debugPrint('==========================================');
    debugPrint('MOCK SENDING 2FA CODE');
    debugPrint('To: $target');
    debugPrint('Method: $method');
    debugPrint('Code: $code');
    debugPrint('==========================================');
  }
}
