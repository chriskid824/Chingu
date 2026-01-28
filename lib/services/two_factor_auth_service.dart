import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 雙因素認證服務 (Two-Factor Authentication Service)
/// 負責處理 SMS 和 Email 的驗證碼發送與驗證邏輯
class TwoFactorAuthService {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  TwoFactorAuthService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  // ---------------------------------------------------------------------------
  // SMS 驗證 (Phone Authentication)
  // ---------------------------------------------------------------------------

  /// 發送 SMS 驗證碼
  ///
  /// [phoneNumber] 手機號碼 (E.164 格式，例如 +886912345678)
  /// [onCodeSent] 當驗證碼發送成功時的回調，提供 verificationId 和 resendToken
  /// [onVerificationFailed] 當驗證失敗時的回調
  /// [onVerificationCompleted] (Android) 當自動驗證成功時的回調
  /// [codeAutoRetrievalTimeout] 當自動接收超時的回調
  Future<void> sendSmsCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android 自動驗證
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout(verificationId);
          }
        },
        forceResendingToken: resendToken,
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        onVerificationFailed(e);
      } else {
        onVerificationFailed(FirebaseAuthException(
          code: 'unknown',
          message: e.toString(),
        ));
      }
    }
  }

  /// 驗證 SMS 驗證碼並獲取憑證
  ///
  /// [verificationId] 從 sendSmsCode 獲取的驗證 ID
  /// [smsCode] 用戶輸入的驗證碼
  ///
  /// 返回 [PhoneAuthCredential]，可用於 signInWithCredential 或 linkWithCredential
  PhoneAuthCredential getSmsCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // ---------------------------------------------------------------------------
  // Email 驗證 (Cloud Functions)
  // ---------------------------------------------------------------------------

  /// 發送 Email 驗證碼
  ///
  /// 注意：此功能依賴後端 Cloud Function 'sendTwoFactorEmail'
  ///
  /// [email] 接收驗證碼的電子郵件
  Future<void> sendEmailCode(String email) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendTwoFactorEmail');
      await callable.call(<String, dynamic>{
        'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('發送 Email 驗證碼失敗: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('發送 Email 驗證碼發生未知錯誤: $e');
    }
  }

  /// 驗證 Email 驗證碼
  ///
  /// 注意：此功能依賴後端 Cloud Function 'verifyTwoFactorEmail'
  ///
  /// [email] 電子郵件
  /// [code] 驗證碼
  ///
  /// 返回 true 表示驗證成功
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifyTwoFactorEmail');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'email': email,
        'code': code,
      });

      final data = result.data as Map<dynamic, dynamic>;
      return data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('驗證 Email 驗證碼失敗: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('驗證 Email 驗證碼發生未知錯誤: $e');
    }
  }
}
