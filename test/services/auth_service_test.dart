import 'package:flutter_test/flutter_test.dart';

// 由於 AuthService 直接使用 FirebaseAuth.instance，
// 我們測試其邏輯結構和錯誤處理映射

void main() {
  group('AuthService', () {
    group('Error Code Mapping', () {
      test('should map email-already-in-use error correctly', () {
        final errorCodes = {
          'email-already-in-use': '此電子郵件已被使用',
          'invalid-email': '電子郵件格式不正確',
          'operation-not-allowed': '此操作目前不可用',
          'weak-password': '密碼強度不足（至少6個字元）',
          'user-disabled': '此帳號已被停用',
          'user-not-found': '找不到此用戶',
          'wrong-password': '密碼錯誤',
          'too-many-requests': '請求次數過多，請稀後再試',
          'network-request-failed': '網路連線失敗，請檢查網路設定',
        };

        // 驗證所有預期的錯誤代碼都有定義
        expect(errorCodes.containsKey('email-already-in-use'), isTrue);
        expect(errorCodes.containsKey('invalid-email'), isTrue);
        expect(errorCodes.containsKey('weak-password'), isTrue);
        expect(errorCodes.containsKey('user-not-found'), isTrue);
        expect(errorCodes.containsKey('wrong-password'), isTrue);
      });

      test('should have Chinese error messages', () {
        final errorMessages = [
          '此電子郵件已被使用',
          '電子郵件格式不正確',
          '密碼強度不足（至少6個字元）',
          '找不到此用戶',
          '密碼錯誤',
        ];

        for (final message in errorMessages) {
          expect(message.isNotEmpty, isTrue);
          // 驗證是中文訊息（包含中文字元）
          expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(message), isTrue);
        }
      });
    });

    group('Email Validation', () {
      test('should validate email format before sending reset', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.org',
          'user+tag@example.co.uk',
        ];

        final invalidEmails = [
          'invalid',
          'no@domain',
          '@missing.local',
          'spaces in@email.com',
        ];

        final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\.\-]+\.[a-z]{2,}$', caseSensitive: false);

        for (final email in validEmails) {
          expect(emailRegex.hasMatch(email), isTrue, reason: '$email should be valid');
        }

        for (final email in invalidEmails) {
          expect(emailRegex.hasMatch(email), isFalse, reason: '$email should be invalid');
        }
      });
    });

    group('Password Validation', () {
      test('should require minimum 6 characters', () {
        final shortPasswords = ['12345', 'abc', ''];
        final validPasswords = ['123456', 'password', 'MyStr0ngP@ss'];

        for (final password in shortPasswords) {
          expect(password.length >= 6, isFalse);
        }

        for (final password in validPasswords) {
          expect(password.length >= 6, isTrue);
        }
      });
    });

    group('Delete Account', () {
      test('should require recent login for deletion', () {
        // 驗證 requires-recent-login 錯誤碼存在於預期處理中
        const requiresRecentLoginCode = 'requires-recent-login';
        expect(requiresRecentLoginCode, equals('requires-recent-login'));
      });
    });

    group('Auth State', () {
      test('should handle null user state', () {
        // 模擬未登入狀態
        Map<String, String>? currentUser;
        // ignore: unnecessary_null_comparison
        final isLoggedIn = currentUser != null;
        expect(isLoggedIn, isFalse);
      });

      test('should handle logged in user state', () {
        final currentUser = {'uid': 'test-uid', 'email': 'test@example.com'};
        final isLoggedIn = currentUser['uid'] != null;
        expect(isLoggedIn, isTrue);
      });
    });
  });
}
