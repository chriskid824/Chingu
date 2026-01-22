import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  String? get verificationId => _verificationId;

  /// 發送驗證碼
  ///
  /// [phoneNumber] 格式必須為 E.164 (例如 +886912345678)
  /// [onCodeSent] 回調函數，當驗證碼發送成功時調用
  /// [onError] 回調函數，當發生錯誤時調用
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only: Auto-resolution (not handling automatic sign-in here to keep flow consistent)
          // But if we wanted to auto-link:
          // await _auth.currentUser?.linkWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? '驗證失敗');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// 驗證 OTP 並更新用戶狀態
  ///
  /// [otp] 用戶輸入的 6 位驗證碼
  Future<void> verifyOTP(String otp) async {
    if (_verificationId == null) throw Exception('Verification ID is null');

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // 連結手機號碼到當前帳戶
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);

        // 更新 Firestore 中的驗證狀態
        await _firestore.collection('users').doc(currentUser.uid).update({
          'isPhoneVerified': true,
          'phoneNumber': currentUser.phoneNumber,
        });
      } else {
        throw Exception('User not logged in');
      }
    } catch (e) {
      throw Exception('驗證碼錯誤或失效: $e');
    }
  }
}
