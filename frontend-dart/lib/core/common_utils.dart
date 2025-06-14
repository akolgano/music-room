// lib/core/common_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommonUtils {
  static String formatDate(DateTime? date) {
    if (date != null) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String? validateRequired(String? value, [String? fieldName]) {
    if (value?.trim().isEmpty ?? true) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter a password';
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? validateMaxLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be less than $maxLength characters';
    }
    return null;
  }
}
