// lib/utils/snackbar_utils.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_strings.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: Colors.blue);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, backgroundColor: Colors.orange);
  }

  static void showLoginSuccess(BuildContext context) {
    showSuccess(context, AppStrings.loginSuccessful);
  }

  static void showAccountCreated(BuildContext context) {
    showSuccess(context, AppStrings.accountCreated);
  }

  static void showPlaylistCreated(BuildContext context) {
    showSuccess(context, AppStrings.playlistCreated);
  }

  static void showPlaylistUpdated(BuildContext context) {
    showSuccess(context, AppStrings.playlistUpdated);
  }

  static void showTrackAdded(BuildContext context, String trackName) {
    showSuccess(context, '${AppStrings.trackAdded}: $trackName');
  }

  static void showTrackRemoved(BuildContext context) {
    showSuccess(context, AppStrings.trackRemoved);
  }

  static void showConnectionError(BuildContext context) {
    showError(context, AppStrings.connectionErrorMessage);
  }

  static void showComingSoon(BuildContext context) {
    showInfo(context, AppStrings.featureComingSoon);
  }

  static void _showSnackBar(
    BuildContext context, 
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
