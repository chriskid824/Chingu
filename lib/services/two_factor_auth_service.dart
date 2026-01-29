import 'package:cloud_functions/cloud_functions.dart';

class TwoFactorAuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 發送 2FA 驗證碼
  ///
  /// [method] 驗證方式 ('email' 或 'sms')
  Future<String?> sendCode(String method) async {
    try {
      final callable = _functions.httpsCallable('sendTwoFactorCode');
      final result = await callable.call(<String, dynamic>{
        'method': method,
      });
      return result.data['demoCode'] as String?;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('發送驗證碼失敗: ${e.message}');
    } catch (e) {
      throw Exception('發送驗證碼發生錯誤: $e');
    }
  }

  /// 驗證 2FA 驗證碼
  ///
  /// [code] 6位數驗證碼
  Future<void> verifyCode(String code) async {
    try {
      final callable = _functions.httpsCallable('verifyTwoFactorCode');
      await callable.call(<String, dynamic>{
        'code': code,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('驗證失敗: ${e.message}');
    } catch (e) {
      throw Exception('驗證過程發生錯誤: $e');
    }
  }
}
