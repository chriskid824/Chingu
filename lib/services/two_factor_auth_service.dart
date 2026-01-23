import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final TwoFactorAuthService _instance = TwoFactorAuthService._internal();

  factory TwoFactorAuthService() {
    return _instance;
  }

  TwoFactorAuthService._internal();

  /// 發送 SMS 驗證碼
  ///
  /// [phoneNumber] 電話號碼 (E.164 格式, e.g., +886912345678)
  /// [onCodeSent] 當驗證碼發送成功時的回調，提供 verificationId
  /// [onVerificationFailed] 當驗證失敗時的回調
  /// [onVerificationCompleted] (選填) Android 自動驗證成功的回調
  Future<void> sendSmsCode({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential)? onVerificationCompleted,
    Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('SMS Auto verification completed');
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('SMS Verification failed: ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS Code sent: $verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('SMS Auto retrieval timeout: $verificationId');
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('Error sending SMS code: $e');
      throw Exception('Failed to send SMS code: $e');
    }
  }

  /// 驗證 SMS 驗證碼
  ///
  /// [verificationId] 從 sendSmsCode 獲得的 ID
  /// [smsCode] 用戶輸入的驗證碼
  /// 返回 [PhoneAuthCredential]
  PhoneAuthCredential getSmsCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// 發送 Email 驗證碼
  ///
  /// 調用 Cloud Function 發送驗證碼到用戶信箱
  Future<void> sendEmailCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in or email is missing');
      }

      final HttpsCallable callable = _functions.httpsCallable('sendTwoFactorEmail');
      await callable.call();
      debugPrint('Email code sent request initiated');
    } catch (e) {
      debugPrint('Error sending email code: $e');
      throw Exception('Failed to send email code: $e');
    }
  }

  /// 驗證 Email 驗證碼
  ///
  /// [code] 用戶輸入的驗證碼
  /// 返回驗證結果 bool
  Future<bool> verifyEmailCode(String code) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifyTwoFactorEmail');
      final result = await callable.call(<String, dynamic>{
        'code': code,
      });

      final data = result.data as Map<dynamic, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error verifying email code: $e');
      return false;
    }
  }

  /// 啟用雙因素認證
  ///
  /// [method] 'sms' 或 'email'
  /// [phoneNumber] 如果是 SMS 方法，需要提供電話號碼
  Future<void> enableTwoFactor({
    required String method,
    String? phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (method == 'sms' && (phoneNumber == null || phoneNumber.isEmpty)) {
      throw Exception('Phone number is required for SMS 2FA');
    }

    final data = {
      'isTwoFactorEnabled': true,
      'twoFactorMethod': method,
    };

    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }

    await _firestore.collection('users').doc(user.uid).update(data);
  }

  /// 停用雙因素認證
  Future<void> disableTwoFactor() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'isTwoFactorEnabled': false,
    });
  }
}
