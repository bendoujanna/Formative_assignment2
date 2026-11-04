import 'constants.dart';

/// Form validation rules. Each one returns an error message, or null when
/// the value is fine, which is what TextFormField expects.
class Validators {
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Name is required';
    if (text.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) return 'Email is required';

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Enter a valid email address';

    final domain = text.split('@').last;
    if (!AppConstants.allowedEmailDomains.contains(domain)) {
      return 'Use your ALU email address';
    }
    return null;
  }

  /// Rule used when creating an account.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Rule used when logging in: only check that something was typed.
  static String? existingPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
