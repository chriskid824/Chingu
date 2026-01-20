import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TwoFactorAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final TwoFactorAuthService _instance = TwoFactorAuthService._internal();
  factory TwoFactorAuthService() => _instance;
  TwoFactorAuthService._internal();

  /// 發送驗證碼
  ///
  /// [userId] 用戶ID
  /// [method] 驗證方式 ('email' 或 'sms')
  /// [contact] 聯絡方式 (Email 或 電話號碼)
  Future<void> sendVerificationCode({
    required String userId,
    required String method,
    required String contact,
  }) async {
    try {
      // 1. 生成 6 位數驗證碼
      final code = _generateCode();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      // 2. 儲存到 Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('verification_codes')
          .doc('current')
          .set({
        'code': code,
        'method': method,
        'contact': contact,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. 模擬發送 (實際應用中應呼叫 Cloud Function)
      if (kDebugMode) {
        print('==========================================');
        print('2FA 驗證碼 (${method.toUpperCase()}): $code');
        print('發送至: $contact');
        print('==========================================');
      }

      // 在真實環境中，這裡會觸發 Cloud Function 發送郵件或簡訊
      // await _functions.httpsCallable('sendTwoFactorCode').call({...});

    } catch (e) {
      debugPrint('發送驗證碼失敗: $e');
      throw Exception('發送驗證碼失敗，請稍後再試');
    }
  }

  /// 驗證代碼
  ///
  /// [userId] 用戶ID
  /// [code] 用戶輸入的代碼
  ///
  /// 返回是否驗證成功
  Future<bool> verifyCode({
    required String userId,
    required String code,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('verification_codes')
          .doc('current');

      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('驗證碼已過期或不存在');
      }

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final storedCode = data['code'] as String;
      final attempts = data['attempts'] as int;

      // 檢查是否過期
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('驗證碼已過期，請重新發送');
      }

      // 檢查嘗試次數 (防止暴力破解)
      if (attempts >= 3) {
        await docRef.delete(); // 刪除以重置
        throw Exception('嘗試次數過多，請重新發送驗證碼');
      }

      // 驗證代碼
      if (storedCode == code) {
        // 驗證成功，刪除代碼
        await docRef.delete();
        return true;
      } else {
        // 驗證失敗，增加嘗試次數
        await docRef.update({'attempts': FieldValue.increment(1)});
        return false;
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('驗證失敗: $e');
    }
  }

  /// 生成 6 位數隨機碼
  String _generateCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// 遮蔽 Email 或電話號碼
  String maskContact(String contact, String method) {
    if (method == 'email') {
      final parts = contact.split('@');
      if (parts.length != 2) return contact;
      final name = parts[0];
      final domain = parts[1];

      if (name.length <= 2) {
        return '${name}***@$domain';
      }
      return '${name.substring(0, 2)}***${name.substring(name.length - 1)}@$domain';
    } else {
      // SMS
      if (contact.length < 4) return contact;
      return '${contact.substring(0, 4)}****${contact.substring(contact.length - 2)}';
    }
  }
}
