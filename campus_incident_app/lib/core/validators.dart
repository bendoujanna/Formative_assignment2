import 'constants.dart';

/// Form validation rules. Each one returns an error message, or null when
/// the value is fine, which is what TextFormField expects
class Validators {
  // accounts

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

  // incident reports

  static const int titleMin = 3;
  static const int titleMax = 80;
  static const int descriptionMin = 10;
  static const int descriptionMax = 500;

  static String? incidentTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Title is required';
    if (text.length < titleMin) {
      return 'Title must be at least $titleMin characters';
    }
    if (text.length > titleMax) {
      return 'Title must be $titleMax characters or fewer';
    }
    return null;
  }

  static String? incidentDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Description is required';
    if (text.length < descriptionMin) {
      return 'Please describe the issue in at least $descriptionMin characters';
    }
    if (text.length > descriptionMax) {
      return 'Description must be $descriptionMax characters or fewer';
    }
    return null;
  }

  static String? requiredChoice(Object? value, String message) {
    return value == null ? message : null;
  }
}
