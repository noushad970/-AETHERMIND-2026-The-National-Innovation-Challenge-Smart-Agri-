/// Lightweight form input validators used by auth + farm record forms.
class Validators {
  Validators._();

  static String? required(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? v) {
    final trimmed = (v ?? '').trim();
    if (trimmed.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\.\-]+$');
    if (!regex.hasMatch(trimmed)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? positiveNumber(String? v, {String fieldName = 'Value'}) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required';
    final n = num.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return '$fieldName must be greater than 0';
    return null;
  }
}
