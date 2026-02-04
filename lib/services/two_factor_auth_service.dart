import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TwoFactorMethod { email, sms }

class TwoFactorAuthService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Constructor allowing dependency injection for testing.
  TwoFactorAuthService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Sends a 2FA verification code via the specified method.
  ///
  /// [method] The method to use ('email' or 'sms').
  Future<void> sendVerificationCode({required TwoFactorMethod method}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendTwoFactorCode');
      final response = await callable.call(<String, dynamic>{
        'method': method.name, // 'email' or 'sms'
      });

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
         throw Exception(data['message'] ?? 'Failed to send code');
      }

    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to send verification code: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('An error occurred while sending code: $e');
    }
  }

  /// Verifies the provided 2FA code.
  ///
  /// [code] The 6-digit code entered by the user.
  /// Returns `true` if valid, `false` otherwise.
  Future<bool> verifyCode({required String code}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifyTwoFactorCode');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'code': code,
      });

      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);

      if (data['valid'] == true) {
        return true;
      } else {
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to verify code: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('An error occurred while verifying code: $e');
    }
  }

  /// Enables 2FA for the current user.
  Future<void> enableTwoFactor() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isTwoFactorEnabled': true,
      });
    } catch (e) {
      throw Exception('Failed to enable 2FA: $e');
    }
  }

  /// Disables 2FA for the current user.
  Future<void> disableTwoFactor() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isTwoFactorEnabled': false,
      });
    } catch (e) {
      throw Exception('Failed to disable 2FA: $e');
    }
  }
}
