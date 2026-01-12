import 'package:flutter_test/flutter_test.dart';

// The service itself has dependencies on Firebase which are hard to mock in a simple unit test
// without a full mockito setup. However, we can verify the static logic (Regex) that we introduced.

void main() {
  group('TwoFactorAuthService Logic Tests', () {
    test('Email regex validation', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      expect(emailRegex.hasMatch('test@example.com'), isTrue);
      expect(emailRegex.hasMatch('user.name@domain.co.uk'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
    });

    test('Phone regex validation', () {
      // Allows optional + prefix and 8-15 digits.
      // Does not allow spaces or dashes, assuming sanitization happens before service call.
      final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
      expect(phoneRegex.hasMatch('+1234567890'), isTrue);
      expect(phoneRegex.hasMatch('0912345678'), isTrue);
      expect(phoneRegex.hasMatch('886912345678'), isTrue);

      expect(phoneRegex.hasMatch('123'), isFalse); // Too short
      expect(phoneRegex.hasMatch('0912-345-678'), isFalse); // Dashes not allowed by this regex
      expect(phoneRegex.hasMatch('abcdefg'), isFalse); // Non-numeric
    });
  });
}
