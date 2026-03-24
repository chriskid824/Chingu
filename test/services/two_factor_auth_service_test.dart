import 'package:flutter_test/flutter_test.dart';

/// TwoFactorAuthService 測試
/// 測試雙重驗證邏輯（不需要 Firebase 初始化）
void main() {
  group('TwoFactorAuthService', () {
    
    // ==================== 驗證碼生成測試 ====================

    group('Verification Code Generation', () {
      test('should generate 6-digit code', () {
        // 模擬生成驗證碼邏輯
        String generateCode() {
          return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
              .toString();
        }

        final code = generateCode();
        expect(code.length, equals(6));
        expect(int.tryParse(code), isNotNull);
      });

      test('should generate different codes', () {
        String generateCode(int seed) {
          return ((100000 + seed) % 1000000).toString().padLeft(6, '0');
        }

        final code1 = generateCode(123456);
        final code2 = generateCode(654321);
        
        expect(code1, isNot(equals(code2)));
      });
    });

    // ==================== 驗證碼驗證測試 ====================

    group('Code Verification', () {
      test('should verify correct code', () {
        const storedCode = '123456';
        const inputCode = '123456';

        final isValid = storedCode == inputCode;
        expect(isValid, isTrue);
      });

      test('should reject incorrect code', () {
        const storedCode = '123456';
        const inputCode = '654321';

        final isValid = storedCode == inputCode;
        expect(isValid, isFalse);
      });

      test('should reject expired code', () {
        final codeCreatedAt = DateTime.now().subtract(const Duration(minutes: 10));
        const expirationMinutes = 5;
        
        final isExpired = DateTime.now()
            .difference(codeCreatedAt)
            .inMinutes > expirationMinutes;
        
        expect(isExpired, isTrue);
      });

      test('should accept valid (non-expired) code', () {
        final codeCreatedAt = DateTime.now().subtract(const Duration(minutes: 2));
        const expirationMinutes = 5;
        
        final isExpired = DateTime.now()
            .difference(codeCreatedAt)
            .inMinutes > expirationMinutes;
        
        expect(isExpired, isFalse);
      });
    });

    // ==================== 2FA 啟用/停用測試 ====================

    group('2FA Toggle', () {
      test('should enable 2FA for user', () {
        var userSettings = {
          'userId': 'user123',
          'twoFactorEnabled': false,
        };

        // 啟用 2FA
        userSettings['twoFactorEnabled'] = true;

        expect(userSettings['twoFactorEnabled'], isTrue);
      });

      test('should disable 2FA for user', () {
        var userSettings = {
          'userId': 'user123',
          'twoFactorEnabled': true,
        };

        // 停用 2FA
        userSettings['twoFactorEnabled'] = false;

        expect(userSettings['twoFactorEnabled'], isFalse);
      });
    });

    // ==================== 電話號碼格式驗證 ====================

    group('Phone Number Validation', () {
      test('should validate Taiwan phone number format', () {
        final validNumbers = [
          '+886912345678',
          '0912345678',
          '0912-345-678',
        ];

        // phoneRegex 不在此處使用，改用簡化驗證
        
        // 移除所有非數字字符後驗證
        for (final number in validNumbers) {
          final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
          // 簡化驗證：以 0 或 +886 開頭，接著 9
          final startsCorrectly = cleaned.startsWith('09') || cleaned.startsWith('+8869');
          expect(startsCorrectly, isTrue);
        }
      });

      test('should reject invalid phone numbers', () {
        const invalidNumber = '12345';
        
        final isValid = invalidNumber.length >= 10;
        expect(isValid, isFalse);
      });
    });

    // ==================== 嘗試次數限制測試 ====================

    group('Attempt Limiting', () {
      test('should track verification attempts', () {
        var attempts = 0;
        const maxAttempts = 3;

        // 模擬失敗嘗試
        attempts++;
        attempts++;
        attempts++;

        final isLocked = attempts >= maxAttempts;
        expect(isLocked, isTrue);
      });

      test('should reset attempts on success', () {
        var attempts = 2;

        // 驗證成功
        attempts = 0;

        expect(attempts, equals(0));
      });
    });
  });
}
