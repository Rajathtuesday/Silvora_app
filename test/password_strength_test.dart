import 'package:flutter_test/flutter_test.dart';
import 'package:silvora_app/crypto/password_strength.dart';

void main() {
  group('PasswordStrength', () {
    test('rejects passwords shorter than 12 characters', () {
      expect(PasswordStrength.validate('Short1!'), isNotNull);
    });

    test('rejects "passwordpassword" (a repeated word, review\'s own example)', () {
      expect(PasswordStrength.validate('passwordpassword'), isNotNull);
    });

    test('rejects "aaaaaaaaaaaa" (a single repeated character, review\'s other example)', () {
      expect(PasswordStrength.validate('aaaaaaaaaaaa'), isNotNull);
    });

    test('rejects a common weak password even past the length floor', () {
      expect(PasswordStrength.validate('password123'), isNotNull);
    });

    test('rejects a long sequential run', () {
      expect(PasswordStrength.validate('abcdefghijkl'), isNotNull);
      expect(PasswordStrength.validate('123456789012'), isNotNull);
    });

    test('rejects low-variety padding that is not a clean repeated substring', () {
      expect(PasswordStrength.validate('aaaaaaaaaaab'), isNotNull);
    });

    test('accepts a genuinely strong random password', () {
      expect(PasswordStrength.validate('Tr0ub4dor&3xile!Vault'), isNull);
    });

    test('accepts a strong passphrase-style password', () {
      expect(PasswordStrength.validate('correct-horse-battery-42!'), isNull);
    });
  });
}
