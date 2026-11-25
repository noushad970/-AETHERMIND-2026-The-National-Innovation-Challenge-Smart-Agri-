/// Utility class for strong password validation rules
class PasswordValidator {
  PasswordValidator._();

  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) =>
      RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) =>
      RegExp(r'[a-z]').hasMatch(password);
  static bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);
  static bool hasSpecialChar(String password) =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=[\]/\\]').hasMatch(password);

  /// Returns true if all password rules pass
  static bool isStrongPassword(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigit(password) &&
        hasSpecialChar(password);
  }

  /// Returns localized validation error message or null if valid
  static String? validate(String? password, {bool isBn = true}) {
    if (password == null || password.isEmpty) {
      return isBn ? 'পাসওয়ার্ড প্রদান করুন' : 'Please enter password';
    }
    if (!hasMinLength(password)) {
      return isBn
          ? 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে'
          : 'Password must be at least 8 characters';
    }
    if (!hasUppercase(password)) {
      return isBn
          ? 'কমপক্ষে ১টি বড় হাতের অক্ষর (A-Z) থাকতে হবে'
          : 'Must contain at least 1 uppercase letter (A-Z)';
    }
    if (!hasLowercase(password)) {
      return isBn
          ? 'কমপক্ষে ১টি ছোট হাতের অক্ষর (a-z) থাকতে হবে'
          : 'Must contain at least 1 lowercase letter (a-z)';
    }
    if (!hasDigit(password)) {
      return isBn
          ? 'কমপক্ষে ১টি সংখ্যা (0-9) থাকতে হবে'
          : 'Must contain at least 1 number (0-9)';
    }
    if (!hasSpecialChar(password)) {
      return isBn
          ? 'কমপক্ষে ১টি স্পেশাল ক্যারেক্টার (@, #, \$, ! ইত্যাদি) থাকতে হবে'
          : 'Must contain at least 1 special character (@, #, \$, ! etc.)';
    }
    return null;
  }
}
