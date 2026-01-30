import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TwoFactorMethod { email, sms }

class TwoFactorAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  TwoFactorAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a verification code to the specified contact.
  ///
  /// [contact] is the phone number (for SMS) or email address (for Email).
  /// [method] specifies the delivery method.
  /// [onCodeSent] callback when code is successfully sent (SMS only provides verificationId).
  /// [onError] callback for errors.
  Future<void> sendVerificationCode({
    required String contact,
    required TwoFactorMethod method,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    if (method == TwoFactorMethod.sms) {
      await _sendSmsCode(contact, onCodeSent, onError);
    } else {
      await _sendEmailCode(contact, onCodeSent, onError);
    }
  }

  Future<void> _sendSmsCode(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification handling.
          // In a strict 2FA flow, we might still want manual code entry,
          // but if the system auto-verifies, we could signal completion here.
          // For now, we rely on the codeSent callback for the manual flow.
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'SMS Verification Failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handling if needed
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> _sendEmailCode(
    String email,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      // Calls a Cloud Function to send the email
      final result = await _functions
          .httpsCallable('sendTwoFactorEmail')
          .call({'email': email});

      final verificationId = result.data['verificationId'] as String? ?? 'email_verification';
      onCodeSent(verificationId);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Verifies the provided code.
  ///
  /// [verificationId] is obtained from [sendVerificationCode].
  /// [code] is the user input.
  Future<bool> verifyCode({
    required String verificationId,
    required String code,
    required TwoFactorMethod method,
  }) async {
    if (method == TwoFactorMethod.sms) {
      return _verifySmsCode(verificationId, code);
    } else {
      return _verifyEmailCode(verificationId, code);
    }
  }

  Future<bool> _verifySmsCode(String verificationId, String code) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    try {
      // Try to link the credential (for enrollment)
      await user.linkWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
        // If already linked, re-authenticate to prove ownership of the second factor
        try {
          await user.reauthenticateWithCredential(credential);
          return true;
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyEmailCode(String verificationId, String code) async {
    try {
      final result = await _functions
          .httpsCallable('verifyTwoFactorEmail')
          .call({
            'verificationId': verificationId,
            'code': code,
          });
      return result.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Enables 2FA for the current user in Firestore.
  /// This should be called AFTER verifyCode returns true.
  Future<void> enableTwoFactor(String userId, TwoFactorMethod method, String contact) async {
    await _firestore.collection('users').doc(userId).update({
      'isTwoFactorEnabled': true,
      'twoFactorMethod': method == TwoFactorMethod.sms ? 'sms' : 'email',
      'phoneNumber': method == TwoFactorMethod.sms ? contact : null, // Store phone if SMS
    });
  }

  /// Disables 2FA for the current user.
  Future<void> disableTwoFactor(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isTwoFactorEnabled': false,
    });
  }
}
