import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

enum TwoFactorMethod { email, sms }

/// 雙因素認證服務
class TwoFactorAuthService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  TwoFactorAuthService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ??
            FirestoreService(firestore: firestore);

  // 集合名稱
  static const String _collection = 'two_factor_codes';

  /// 發送驗證碼
  ///
  /// [target] 發送目標 (Email 或 Phone Number)
  /// [method] 發送方式 (TwoFactorMethod.email 或 TwoFactorMethod.sms)
  /// [uid] 用戶 ID (如果已知)
  Future<void> sendVerificationCode({
    required String target,
    required TwoFactorMethod method,
    String? uid,
  }) async {
    try {
      // 驗證輸入格式
      _validateTarget(target, method);

      // 1. 生成 6 位數驗證碼
      final code = _generateCode();

      // 2. 設定過期時間 (10分鐘)
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // 3. 儲存到 Firestore
      await _firestore.collection(_collection).doc(target).set({
        // TODO: In production, do NOT store the plain text code in a client-readable document.
        // This should be handled by a Cloud Function.
        'code': code,
        'method': method.name,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
        'attempts': 0,
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
    } catch (e) {
      debugPrint('驗證代碼失敗: $e');
      if (e.toString().contains('Exception:')) {
        rethrow; // 保持原始錯誤訊息
      }
      throw Exception('驗證失敗: $e');
    }
  }

  /// 啟用 2FA
  ///
  /// [uid] 用戶 ID
  /// [method] 驗證方式
  /// [phoneNumber] 電話號碼 (如果 method 是 sms)
  Future<void> enableTwoFactor(String uid, TwoFactorMethod method, {String? phoneNumber}) async {
    try {
      if (method == TwoFactorMethod.sms) {
        if (phoneNumber == null || phoneNumber.isEmpty) {
          throw Exception('啟用 SMS 驗證需要電話號碼');
        }
        _validateTarget(phoneNumber, TwoFactorMethod.sms);
      }

      final updates = {
        'isTwoFactorEnabled': true,
        'twoFactorMethod': method.name,
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

  /// 驗證目標格式
  void _validateTarget(String target, TwoFactorMethod method) {
    if (method == TwoFactorMethod.email) {
      // 簡單的 Email 正則驗證
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (!emailRegex.hasMatch(target)) {
        throw Exception('無效的電子郵件格式');
      }
    } else if (method == TwoFactorMethod.sms) {
      // 簡單的電話號碼驗證 (至少8位，允許+號)
      if (target.isEmpty || target.length < 8) {
        throw Exception('無效的電話號碼');
      }
    }
  }

  /// 生成 6 位數隨機代碼
  String _generateCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// 模擬發送代碼
  void _mockSendCode(String target, String code, TwoFactorMethod method) {
    debugPrint('==========================================');
    debugPrint('MOCK SENDING 2FA CODE');
    debugPrint('To: $target');
    debugPrint('Method: ${method.name}');
    debugPrint('Code: $code');
    debugPrint('==========================================');
  }
}
