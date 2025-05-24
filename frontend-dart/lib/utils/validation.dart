// lib/utils/validation.dart
String? validateRequired(String? value, String fieldName) {
  if (value?.isEmpty ?? true) return 'Please enter $fieldName';
  return null;
}

String? validateEmail(String? value) {
  if (value?.isEmpty ?? true) return 'Please enter an email';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
    return 'Please enter a valid email';
  }
  return null;
}
