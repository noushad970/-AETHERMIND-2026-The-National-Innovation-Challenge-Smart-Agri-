import 'package:flutter_test/flutter_test.dart';
import 'package:ai_agri_assistant/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator Tests', () {
    test('Validates strong passwords correctly', () {
      expect(PasswordValidator.isStrongPassword('StrongP@ss1'), isTrue);
      expect(PasswordValidator.validate('StrongP@ss1'), isNull);
    });

    test('Rejects weak passwords missing uppercase', () {
      expect(PasswordValidator.hasUppercase('weakpass1!'), isFalse);
      expect(PasswordValidator.isStrongPassword('weakpass1!'), isFalse);
    });

    test('Rejects weak passwords missing lowercase', () {
      expect(PasswordValidator.hasLowercase('WEAKPASS1!'), isFalse);
      expect(PasswordValidator.isStrongPassword('WEAKPASS1!'), isFalse);
    });

    test('Rejects weak passwords missing numbers', () {
      expect(PasswordValidator.hasDigit('WeakPass!'), isFalse);
      expect(PasswordValidator.isStrongPassword('WeakPass!'), isFalse);
    });

    test('Rejects weak passwords missing special characters', () {
      expect(PasswordValidator.hasSpecialChar('WeakPass123'), isFalse);
      expect(PasswordValidator.isStrongPassword('WeakPass123'), isFalse);
    });

    test('Rejects short passwords', () {
      expect(PasswordValidator.hasMinLength('P@1a'), isFalse);
      expect(PasswordValidator.isStrongPassword('P@1a'), isFalse);
    });
  });
}
