// lib/utils/validation_utils.dart
import 'package:flutter/material.dart';

class ValidationUtils {
  
  static String? required(String? value, [String? fieldName]) {
    if (value?.trim().isEmpty ?? true) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    return null;
  }

  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter a password';
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value?.isEmpty ?? true) return 'Please confirm your password';
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? username(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a username';
    if (value!.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be less than 30 characters';
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? phoneNumber(String? value, {bool required = false}) {
    if (value?.isEmpty ?? true) {
      return required ? 'Please enter a phone number' : null;
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }
    
    return null;
  }

  static String? url(String? value, {bool required = false}) {
    if (value?.isEmpty ?? true) {
      return required ? 'Please enter a URL' : null;
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    if (!urlRegex.hasMatch(value!)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value != null && value.length < minLength) {
      return '${fieldName ?? 'Field'} must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be less than $maxLength characters';
    }
    return null;
  }

  static String? lengthRange(String? value, int minLength, int maxLength, [String? fieldName]) {
    if (value != null) {
      if (value.length < minLength) {
        return '${fieldName ?? 'Field'} must be at least $minLength characters';
      }
      if (value.length > maxLength) {
        return '${fieldName ?? 'Field'} must be less than $maxLength characters';
      }
    }
    return null;
  }

  static String? isNumber(String? value, [String? fieldName]) {
    if (value?.isEmpty ?? true) return null;
    
    if (double.tryParse(value!) == null) {
      return '${fieldName ?? 'Field'} must be a valid number';
    }
    return null;
  }

  static String? isInteger(String? value, [String? fieldName]) {
    if (value?.isEmpty ?? true) return null;
    
    if (int.tryParse(value!) == null) {
      return '${fieldName ?? 'Field'} must be a valid integer';
    }
    return null;
  }

  static String? numberRange(String? value, double min, double max, [String? fieldName]) {
    if (value?.isEmpty ?? true) return null;
    
    final number = double.tryParse(value!);
    if (number == null) {
      return '${fieldName ?? 'Field'} must be a valid number';
    }
    
    if (number < min || number > max) {
      return '${fieldName ?? 'Field'} must be between $min and $max';
    }
    return null;
  }

  static String? pastDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;
    
    if (value.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Date'} must be in the past';
    }
    return null;
  }

  static String? futureDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;
    
    if (value.isBefore(DateTime.now())) {
      return '${fieldName ?? 'Date'} must be in the future';
    }
    return null;
  }

  static String? dateRange(DateTime? value, DateTime? minDate, DateTime? maxDate, [String? fieldName]) {
    if (value == null) return null;
    
    if (minDate != null && value.isBefore(minDate)) {
      return '${fieldName ?? 'Date'} must be after ${_formatDate(minDate)}';
    }
    
    if (maxDate != null && value.isAfter(maxDate)) {
      return '${fieldName ?? 'Date'} must be before ${_formatDate(maxDate)}';
    }
    
    return null;
  }

  static String? age(DateTime? birthDate, int minAge, int maxAge) {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final monthDifference = now.month - birthDate.month;
    final dayDifference = now.day - birthDate.day;
    
    int actualAge = age;
    if (monthDifference < 0 || (monthDifference == 0 && dayDifference < 0)) {
      actualAge--;
    }
    
    if (actualAge < minAge || actualAge > maxAge) {
      return 'Age must be between $minAge and $maxAge years';
    }
    
    return null;
  }

  static String? pattern(String? value, RegExp pattern, String errorMessage) {
    if (value?.isEmpty ?? true) return null;
    
    if (!pattern.hasMatch(value!)) {
      return errorMessage;
    }
    return null;
  }

  static String? fileExtension(String? fileName, List<String> allowedExtensions) {
    if (fileName?.isEmpty ?? true) return null;
    
    final extension = fileName!.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'File must be one of: ${allowedExtensions.join(', ')}';
    }
    return null;
  }

  static String? fileSize(int? fileSizeBytes, int maxSizeBytes) {
    if (fileSizeBytes == null) return null;
    
    if (fileSizeBytes > maxSizeBytes) {
      final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'File size must be less than ${maxSizeMB}MB';
    }
    return null;
  }

  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  static String? Function(String?) conditional(
    bool Function() condition,
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (condition()) {
        return validator(value);
      }
      return null;
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ValidationBuilder {
  final List<String? Function(String?)> _validators = [];

  ValidationBuilder required([String? fieldName]) {
    _validators.add((value) => ValidationUtils.required(value, fieldName));
    return this;
  }

  ValidationBuilder email() {
    _validators.add(ValidationUtils.email);
    return this;
  }

  ValidationBuilder password([int minLength = 8]) {
    _validators.add((value) => ValidationUtils.password(value, minLength));
    return this;
  }

  ValidationBuilder username() {
    _validators.add(ValidationUtils.username);
    return this;
  }

  ValidationBuilder phone({bool required = false}) {
    _validators.add((value) => ValidationUtils.phoneNumber(value, required: required));
    return this;
  }

  ValidationBuilder minLength(int length, [String? fieldName]) {
    _validators.add((value) => ValidationUtils.minLength(value, length, fieldName));
    return this;
  }

  ValidationBuilder maxLength(int length, [String? fieldName]) {
    _validators.add((value) => ValidationUtils.maxLength(value, length, fieldName));
    return this;
  }

  ValidationBuilder lengthRange(int min, int max, [String? fieldName]) {
    _validators.add((value) => ValidationUtils.lengthRange(value, min, max, fieldName));
    return this;
  }

  ValidationBuilder pattern(RegExp pattern, String errorMessage) {
    _validators.add((value) => ValidationUtils.pattern(value, pattern, errorMessage));
    return this;
  }

  ValidationBuilder custom(String? Function(String?) validator) {
    _validators.add(validator);
    return this;
  }

  ValidationBuilder conditional(bool Function() condition, String? Function(String?) validator) {
    _validators.add(ValidationUtils.conditional(condition, validator));
    return this;
  }

  String? Function(String?) build() {
    return ValidationUtils.compose(_validators);
  }
}

class ValidationPatterns {
  static final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  static final RegExp alphabetic = RegExp(r'^[a-zA-Z]+$');
  static final RegExp numeric = RegExp(r'^[0-9]+$');
  static final RegExp alphanumericWithSpaces = RegExp(r'^[a-zA-Z0-9\s]+$');
  static final RegExp noSpecialChars = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
  static final RegExp strongPassword = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]');
  static final RegExp postalCode = RegExp(r'^\d{5,6}$');
  static final RegExp creditCard = RegExp(r'^[0-9]{13,19}$');
  static final RegExp ipAddress = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
}

class CommonValidators {
  static final playlistName = ValidationBuilder()
      .required('playlist name')
      .minLength(1)
      .maxLength(100)
      .build();

  static final trackName = ValidationBuilder()
      .required('track name')
      .minLength(1)
      .maxLength(200)
      .build();

  static final description = ValidationBuilder()
      .maxLength(500, 'description')
      .build();

  static final bio = ValidationBuilder()
      .maxLength(500, 'bio')
      .build();

  static final location = ValidationBuilder()
      .maxLength(100, 'location')
      .build();

  static final firstName = ValidationBuilder()
      .required('first name')
      .minLength(1)
      .maxLength(50)
      .pattern(ValidationPatterns.alphabetic, 'First name can only contain letters')
      .build();

  static final lastName = ValidationBuilder()
      .required('last name')
      .minLength(1)
      .maxLength(50)
      .pattern(ValidationPatterns.alphabetic, 'Last name can only contain letters')
      .build();

  static final postalCode = ValidationBuilder()
      .required('postal code')
      .pattern(ValidationPatterns.postalCode, 'Please enter a valid postal code')
      .build();
}
