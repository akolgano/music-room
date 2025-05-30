// lib/utils/validation.dart
import '../core/constants.dart';
import '../core/app_strings.dart';

class ValidationUtils {
  static String? validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return '${AppStrings.pleaseEnter} ${fieldName.toLowerCase()}';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return AppStrings.pleaseEnterEmail;
    if (!RegExp(AppConstants.emailRegexPattern).hasMatch(value!)) {
      return AppStrings.pleaseEnterValidEmail;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) return AppStrings.pleaseEnterPassword;
    if (value!.length < AppConstants.minPasswordLength) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? validateUsername(String? value) {
    return validateRequired(value, AppStrings.username);
  }

  static String? validatePlaylistName(String? value) {
    return validateRequired(value, AppStrings.playlistName);
  }

  static String? validateTrackName(String? value) {
    return validateRequired(value, AppStrings.track);
  }
}
