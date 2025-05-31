// lib/utils/validation.dart
class Validators {
  static String? required(String? value, String fieldName) {
    if (value?.isEmpty ?? true) return 'Please enter $fieldName';
    return null;
  }

  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter password';
    if (value!.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
